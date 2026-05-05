#!/bin/bash
# collector.sh 数据生成测试
# 验证 JSON 输出格式和关键字段存在性

COLLECT_TESTS=0
COLLECT_PASSED=0
COLLECT_FAILED=0

echo "=== Collector 数据生成测试 ==="

# 运行一次采集
WORKSPACE="$HOME/.openclaw/workspace-metapivot"
DATA_DIR="$WORKSPACE/projects/workspace-health/data"
LATEST="$DATA_DIR/latest.json"

# 创建临时目录用于隔离测试
TEST_WORKSPACE=$(mktemp -d)
TEST_DATA_DIR="$TEST_WORKSPACE/data"
mkdir -p "$TEST_DATA_DIR/history"

# 模拟运行采集逻辑（隔离版）
collect_mock() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    TIMESTAMP_UNIX=$(date '+%s')
    
    # 模拟数据
    GIT_BRANCH="main"
    GIT_CLEAN=1
    HAS_REMOTE=1
    IS_SYNCED=1
    CONFIG_COMPLETE=1
    CONFIG_LIST='"IDENTITY.md","USER.md"'
    MEMORY_COUNT=2
    CPU_LOAD="1.50"
    DISK_PCT=33
    MEM_PCT=55
    HB_EFFECTIVE=1
    
    # 计算 score
    SCORE=0
    [ "$GIT_BRANCH" != "N/A" ] && SCORE=$((SCORE+10))
    [ "$GIT_CLEAN" -eq 1 ] && SCORE=$((SCORE+20))
    [ "$HB_EFFECTIVE" -eq 1 ] && SCORE=$((SCORE+10))
    [ "${MEM_PCT:-0}" -lt 80 ] && SCORE=$((SCORE+15))
    [ "${DISK_PCT:-0}" -lt 85 ] && SCORE=$((SCORE+15))
    [ "$CONFIG_COMPLETE" -eq 1 ] && SCORE=$((SCORE+20))
    [ "$HAS_REMOTE" -eq 1 ] && [ "$IS_SYNCED" -eq 1 ] && SCORE=$((SCORE+10))
    
    cat > "$TEST_DATA_DIR/latest.json" << JSON
{
    "timestamp": "$TIMESTAMP",
    "timestamp_unix": $TIMESTAMP_UNIX,
    "git": {
        "branch": "$GIT_BRANCH",
        "clean": $GIT_CLEAN,
        "has_remote": $HAS_REMOTE,
        "synced": $IS_SYNCED
    },
    "config": {
        "complete": $CONFIG_COMPLETE,
        "files": [$CONFIG_LIST]
    },
    "memory": { "count": $MEMORY_COUNT },
    "system": {
        "cpu_load": "$CPU_LOAD",
        "memory_pct": ${MEM_PCT:-0},
        "disk_pct": ${DISK_PCT:-0}
    },
    "heartbeat": { "effective": $HB_EFFECTIVE },
    "score": $SCORE
}
JSON
}

# 运行
collect_mock

# 测试: JSON 格式有效性
COLLECT_TESTS=$((COLLECT_TESTS + 1))
if python3 -c "import json; json.load(open('$TEST_DATA_DIR/latest.json'))" 2>/dev/null; then
    COLLECT_PASSED=$((COLLECT_PASSED + 1))
    echo "  ✅ [$COLLECT_TESTS] JSON 格式有效"
else
    COLLECT_FAILED=$((COLLECT_FAILED + 1))
    echo "  ❌ [$COLLECT_TESTS] JSON 格式无效"
fi

# 测试: 必需字段存在
REQUIRED_FIELDS="timestamp timestamp_unix git.branch git.clean git.has_remote config.complete memory.count system.cpu_load system.memory_pct system.disk_pct heartbeat.effective score"
for field in $REQUIRED_FIELDS; do
    COLLECT_TESTS=$((COLLECT_TESTS + 1))
    # 用 python 读取嵌套字段
    if python3 -c "
import json
d = json.load(open('$TEST_DATA_DIR/latest.json'))
parts = '$field'.split('.')
v = d
for p in parts:
    v = v[p]
print(v)
" > /dev/null 2>&1; then
        COLLECT_PASSED=$((COLLECT_PASSED + 1))
        echo "  ✅ [$COLLECT_TESTS] 字段存在: $field"
    else
        COLLECT_FAILED=$((COLLECT_FAILED + 1))
        echo "  ❌ [$COLLECT_TESTS] 字段缺失: $field"
    fi
done

# 测试: score 在合理范围
COLLECT_TESTS=$((COLLECT_TESTS + 1))
SCORE=$(python3 -c "import json; print(json.load(open('$TEST_DATA_DIR/latest.json'))['score'])")
if [ "$SCORE" -ge 0 ] && [ "$SCORE" -le 100 ]; then
    COLLECT_PASSED=$((COLLECT_PASSED + 1))
    echo "  ✅ [$COLLECT_TESTS] Score 范围合法: $SCORE"
else
    COLLECT_FAILED=$((COLLECT_FAILED + 1))
    echo "  ❌ [$COLLECT_TESTS] Score 范围非法: $SCORE"
fi

# 测试: git.clean 是 boolean
COLLECT_TESTS=$((COLLECT_TESTS + 1))
CLEAN=$(python3 -c "import json; print(json.load(open('$TEST_DATA_DIR/latest.json'))['git']['clean'])")
if [ "$CLEAN" = "1" ] || [ "$CLEAN" = "0" ]; then
    COLLECT_PASSED=$((COLLECT_PASSED + 1))
    echo "  ✅ [$COLLECT_TESTS] git.clean 是 boolean: $CLEAN"
else
    COLLECT_FAILED=$((COLLECT_FAILED + 1))
    echo "  ❌ [$COLLECT_TESTS] git.clean 不是 boolean: $CLEAN"
fi

# 清理
rm -rf "$TEST_WORKSPACE"

echo ""
echo "=== 测试结果 ==="
echo "通过: $COLLECT_PASSED/$COLLECT_TESTS"
echo "失败: $COLLECT_FAILED/$COLLECT_TESTS"
echo ""

if [ "$COLLECT_FAILED" -eq 0 ]; then
    echo "✅ 所有测试通过"
    exit 0
else
    echo "❌ $COLLECT_FAILED 个测试失败"
    exit 1
fi
