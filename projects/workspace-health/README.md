# 🫀 Workspace 健康监控仪表盘

> v2 — 实时监控 + 飞书告警

## 功能

| 功能 | 说明 |
|------|------|
| 📊 健康评分 | 0-100 分，7 项评分维度 |
| 📈 历史趋势 | 健康分历史曲线图 |
| ⏱️ 定时刷新 | 可配置 30s / 1m / 2m / 5m 自动刷新 |
| 🔔 飞书告警 | 健康分异常时自动推送飞书消息 |
| 📁 实时数据 | 每次刷新调用真实命令采集最新状态 |

### 健康评分维度

| 项目 | 分数 |
|------|------|
| Git 分支正常 | +10 |
| 工作树干净 | +20 |
| HEARTBEAT 有效配置 | +10 |
| 内存使用 < 80% | +15 |
| 磁盘使用 < 85% | +15 |
| 七份核心配置文件完整 | +20 |
| Remote 已同步 | +10 |

### 告警分级

| 级别 | 条件 | 动作 |
|------|------|------|
| 🔴 紧急 | 健康分 < 40 | 立即告警 |
| 🟡 警告 | 40 ≤ 分 < 60 | 记录 + 告警 |
| ✅ 恢复 | 异常 → 正常 | 恢复通知 |

## 快速开始

### 1. 配置飞书 Webhook

```bash
# 复制配置模板
cp ~/.metapivot/secrets.env.template ~/.metapivot/secrets.env

# 编辑填入你的 Webhook URL
vim ~/.metapivot/secrets.env
# 或设置环境变量
export FEISHU_WEBHOOK_URL='https://open.feishu.cn/open-apis/bot/v2/hook/xxx'
```

获取 Webhook URL: 飞书群 → 设置 → 群机器人 → 添加机器人 → 自定义 → 复制 Webhook 地址

### 2. 启动监控

```bash
cd ~/.openclaw/workspace-metapivot

# 启动后台采集器（包含告警检查）
bash projects/workspace-health/collector.sh

# 或分别启动（采集器 + 告警分离）
bash projects/workspace-health/collector.sh &  # 后台采集
open projects/workspace-health/dashboard.html   # 浏览器看面板
```

### 3. 测试告警

```bash
# 测试 webhook 是否可用
bash projects/workspace-health/alerter.sh test

# 查看告警日志
cat projects/workspace-health/data/alerts/alert.log
```

## 组件说明

### collector.sh
后台数据采集器，每分钟采集一次，写入 `data/latest.json`，并自动检查是否需要告警。

```bash
# 指定采集间隔（秒）
bash collector.sh 30
```

### alerter.sh
飞书 webhook 告警服务。

```bash
# 发送测试消息
bash alerter.sh test

# 手动检查并告警
bash alerter.sh check [json_file]

# 查看帮助
bash alerter.sh help
```

### dashboard.html
实时监控面板，浏览器打开即可，无需服务器。

```bash
open projects/workspace-health/dashboard.html
```

## 文件结构

```
projects/workspace-health/
├── collector.sh          # 后台采集器（daemon）
├── alerter.sh            # 飞书告警服务
├── dashboard.html        # 实时监控面板
├── workspace-health.sh   # 单次报告生成器
├── data/
│   ├── latest.json       # 实时数据
│   ├── history/          # 历史数据
│   └── alerts/           # 告警记录
│       └── alert.log     # 告警日志
└── README.md
```

## 技术实现

- **数据采集**: 纯 bash + exec 调用真实命令
- **告警服务**: bash + curl + 飞书 webhook API
- **前端**: 纯 HTML + CSS + JS，Canvas 图表，无框架依赖
- **Secrets**: 环境变量或 `~/.metapivot/secrets.env`
- **重试机制**: 最多 3 次，指数退避 (1s → 2s → 4s)
- **去重**: 基于 `data/alerts/.sent_<key>` 文件记录

## 依赖

- bash
- curl
- python3 (用于 JSON 解析)
- git
- vm_stat / df / uptime (macOS 系统命令)
