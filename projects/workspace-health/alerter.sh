#!/bin/bash
# Workspace Health Alerter - 飞书 webhook 通知服务
# 用法:
#   bash alerter.sh test                    # 发送测试消息
#   bash alerter.sh check <json_file>      # 检查数据并决定是否告警

set -e

WORKSPACE="$HOME/.openclaw/workspace-metapivot"
ALERT_DIR="$WORKSPACE/projects/workspace-health/data/alerts"
SECRETS_FILE="$HOME/.metapivot/secrets.env"
LOG_FILE="$ALERT_DIR/alert.log"
DATA_FILE="${2:-$WORKSPACE/projects/workspace-health/data/latest.json}"

# 颜色定义（用于日志）
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# 1. Secrets 管理：加载飞书 Webhook URL
# ============================================
load_secrets() {
    if [ -f "$SECRETS_FILE" ]; then
        # 支持 source 格式的 secrets 文件
        FEISHU_WEBHOOK=$(grep "^FEISHU_WEBHOOK=" "$SECRETS_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    fi
    
    # 环境变量优先
    FEISHU_WEBHOOK="${FEISHU_WEBHOOK:-${FEISHU_WEBHOOK_URL}}"
    
    if [ -z "$FEISHU_WEBHOOK" ]; then
        echo -e "${RED}❌ 错误: 未找到飞书 Webhook URL${NC}"
        echo "请设置以下之一:"
        echo "  1. 环境变量: export FEISHU_WEBHOOK_URL='https://open.feishu.cn/...'"
        echo "  2. 文件: ~/.metapivot/secrets.env，内容: FEISHU_WEBHOOK='https://open.feishu.cn/...'"
        return 1
    fi
    
    return 0
}

# ============================================
# 2. 网络请求：带重试的 webhook 调用
# ============================================
send_webhook() {
    local payload="$1"
    local max_retries=3
    local retry_delay=1
    local attempt=0
    local response_code
    
    while [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))
        
        # 调用飞书 webhook
        response=$(curl -s -w "\n%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "$FEISHU_WEBHOOK" 2>&1)
        
        # 分离 HTTP 状态码和响应体
        http_code=$(echo "$response" | tail -1)
        response_body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            # 检查响应是否是 {"code":0, "msg":"ok"}
            if echo "$response_body" | grep -q '"code":0'; then
                echo -e "${GREEN}✅ 消息发送成功 (尝试 $attempt/${max_retries})${NC}"
                return 0
            fi
        fi
        
        if [ $attempt -lt $max_retries ]; then
            echo -e "${YELLOW}⚠️ 发送失败 (尝试 $attempt/${max_retries})，${retry_delay}s 后重试...${NC}"
            sleep $retry_delay
            retry_delay=$((retry_delay * 2))  # 指数退避
        fi
    done
    
    echo -e "${RED}❌ 发送失败，已重试 ${max_retries} 次${NC}"
    return 1
}

# ============================================
# 3. 飞书消息卡片构建
# ============================================
build_alert_card() {
    local level="$1"       # critical / warning / recovery
    local score="$2"
    local reason="$3"
    local details="$4"
    local timestamp="$5"
    
    # 颜色：critical=红色, warning=橙色, recovery=绿色
    case "$level" in
        critical)
            color="red"
            emoji="🔴"
            title="紧急告警"
            ;;
        warning)
            color="orange"
            emoji="🟡"
            title="警告"
            ;;
        recovery)
            color="green"
            emoji="✅"
            title="恢复通知"
            ;;
    esac
    
    # 构建飞书消息卡片 (Feishu card v2 格式)
    cat << JSON
{
    "msg_type": "interactive",
    "card": {
        "header": {
            "title": {
                "tag": "plain_text",
                "content": "$emoji $title - Workspace 健康异常"
            },
            "template": "$color"
        },
        "elements": [
            {
                "tag": "div",
                "text": {
                    "tag": "lark_md",
                    "content": "**健康评分:** $score / 100\n**原因:** $reason\n\n$details"
                }
            },
            {
                "tag": "hr"
            },
            {
                "tag": "note",
                "elements": [
                    {
                        "tag": "plain_text",
                        "content": "报告时间: $timestamp"
                    }
                ]
            }
        ]
    }
}
JSON
}

# ============================================
# 4. 告警去重检查
# ============================================
is_alert_sent() {
    local alert_key="$1"  # 格式: <level>_<reason>
    local sent_file="$ALERT_DIR/.sent_${alert_key}"
    
    [ -f "$sent_file" ] && return 0  # 已发送
    return 1  # 未发送
}

mark_alert_sent() {
    local alert_key="$1"
    local sent_file="$ALERT_DIR/.sent_${alert_key}"
    touch "$sent_file"
}

clear_alert_sent() {
    local alert_key="$1"
    local sent_file="$ALERT_DIR/.sent_${alert_key}"
    rm -f "$sent_file"
}

# ============================================
# 5. 日志记录
# ============================================
log_alert() {
    local level="$1"
    local score="$2"
    local message="$3"
    local status="$4"  # sent / failed / skipped
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] [score=$score] [$status] $message" >> "$LOG_FILE"
}

# ============================================
# 6. 告警判断主逻辑
# ============================================
check_and_alert() {
    local data_file="$1"
    
    if [ ! -f "$data_file" ]; then
        echo -e "${RED}❌ 数据文件不存在: $data_file${NC}"
        return 1
    fi
    
    # 解析 JSON
    local score=$(python3 -c "import json; print(json.load(open('$data_file'))['score'])" 2>/dev/null)
    local git_branch=$(python3 -c "import json; print(json.load(open('$data_file'))['git']['branch'])" 2>/dev/null)
    local git_clean=$(python3 -c "import json; print(json.load(open('$data_file'))['git']['clean'])" 2>/dev/null)
    local disk_pct=$(python3 -c "import json; print(json.load(open('$data_file'))['system']['disk_pct'])" 2>/dev/null)
    local mem_pct=$(python3 -c "import json; print(json.load(open('$data_file'))['system']['memory_pct'])" 2>/dev/null)
    local heartbeat_effective=$(python3 -c "import json; print(json.load(open('$data_file'))['heartbeat']['effective'])" 2>/dev/null)
    local config_complete=$(python3 -c "import json; print(json.load(open('$data_file'))['config']['complete'])" 2>/dev/null)
    local timestamp=$(python3 -c "import json; print(json.load(open('$data_file'))['timestamp'])" 2>/dev/null)
    
    score=${score:-100}
    git_branch=${git_branch:-unknown}
    git_clean=${git_clean:-1}
    disk_pct=${disk_pct:-0}
    mem_pct=${mem_pct:-0}
    heartbeat_effective=${heartbeat_effective:-0}
    config_complete=${config_complete:-1}
    
    # 构建详情
    local details="**分支:** \`$git_branch\`
**工作树:** $([ "$git_clean" = "1" ] && echo '✅ 干净' || echo '⚠️ 有更改')
**磁盘:** ${disk_pct}%
**内存:** ${mem_pct}%
**HEARTBEAT:** $([ "$heartbeat_effective" = "1" ] && echo '✅ 有效' || echo '❌ 空')
**配置文件:** $([ "$config_complete" = "1" ] && echo '✅ 完整' || echo '❌ 缺失')"
    
    # 判断告警级别
    local level=""
    local reason=""
    local alert_key=""
    
    if [ "$score" -lt 40 ]; then
        level="critical"
        reason="健康分严重异常"
        alert_key="critical_score_${score}"
    elif [ "$score" -lt 60 ]; then
        level="warning"
        reason="健康分偏低"
        alert_key="warning_score_${score}"
    fi
    
    # 检查是否需要恢复通知
    local prev_score=""
    local prev_alert_key=""
    if [ -f "$ALERT_DIR/.last_score" ]; then
        prev_score=$(cat "$ALERT_DIR/.last_score")
        if [ "$prev_score" -lt 60 ] && [ "$score" -ge 60 ]; then
            # 恢复到正常状态
            level="recovery"
            reason="健康分已恢复正常"
            alert_key="recovery_score_${score}"
            clear_alert_sent "critical_score"
            clear_alert_sent "warning_score"
        fi
    fi
    
    # 记录当前分数
    echo "$score" > "$ALERT_DIR/.last_score"
    
    # 如果没有异常级别，直接返回
    if [ -z "$level" ]; then
        echo -e "${GREEN}✅ 健康分正常 ($score)，无需告警${NC}"
        return 0
    fi
    
    # 检查去重
    if is_alert_sent "$alert_key"; then
        echo -e "${YELLOW}⚠️ 告警已发送过，跳过: $alert_key${NC}"
        log_alert "$level" "$score" "$reason" "skipped"
        return 0
    fi
    
    # 发送告警
    local payload=$(build_alert_card "$level" "$score" "$reason" "$details" "$timestamp")
    
    if send_webhook "$payload"; then
        mark_alert_sent "$alert_key"
        log_alert "$level" "$score" "$reason" "sent"
        echo -e "${GREEN}✅ 告警已发送: $emoji $reason (分=$score)${NC}"
    else
        log_alert "$level" "$score" "$reason" "failed"
        echo -e "${RED}❌ 告警发送失败${NC}"
        return 1
    fi
}

# ============================================
# 7. 测试模式
# ============================================
send_test_message() {
    echo -e "${BLUE}🧪 发送测试消息...${NC}"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local payload=$(cat << JSON
{
    "msg_type": "interactive",
    "card": {
        "header": {
            "title": {
                "tag": "plain_text",
                "content": "🧪 元枢监控测试消息"
            },
            "template": "blue"
        },
        "elements": [
            {
                "tag": "div",
                "text": {
                    "tag": "lark_md",
                    "content": "这是一条来自 **元枢 Workspace Health** 的测试消息。\n\n如果你看到这条消息，说明飞书 webhook 已正确配置。"
                }
            },
            {
                "tag": "hr"
            },
            {
                "tag": "note",
                "elements": [
                    {
                        "tag": "plain_text",
                        "content": "发送时间: $timestamp"
                    }
                ]
            }
        ]
    }
}
JSON
)
    
    if send_webhook "$payload"; then
        echo -e "${GREEN}✅ 测试消息发送成功${NC}"
        log_alert "test" "N/A" "测试消息发送成功" "sent"
        return 0
    else
        echo -e "${RED}❌ 测试消息发送失败${NC}"
        return 1
    fi
}

# ============================================
# 主入口
# ============================================
main() {
    mkdir -p "$ALERT_DIR"
    
    case "$1" in
        test)
            load_secrets || exit 1
            send_test_message
            ;;
        check)
            load_secrets || exit 1
            check_and_alert "$DATA_FILE"
            ;;
        help|--help|-h)
            echo "用法:"
            echo "  bash alerter.sh test              # 发送测试消息"
            echo "  bash alerter.sh check [json_file] # 检查数据并告警"
            echo "  bash alerter.sh help              # 显示帮助"
            echo ""
            echo "环境要求:"
            echo "  设置 FEISHU_WEBHOOK_URL 环境变量，或"
            echo "  创建 ~/.metapivot/secrets.env 文件，内容: FEISHU_WEBHOOK='你的webhook地址'"
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo "使用 'bash alerter.sh help' 查看帮助"
            exit 1
            ;;
    esac
}

main "$@"
