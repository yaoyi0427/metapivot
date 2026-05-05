# 🫀 Workspace 健康监控服务

> v3 — 服务化版本，开机自启、持续监控

## 功能

| 功能 | 说明 |
|------|------|
| 📊 健康评分 | 0-100 分，7 项评分维度 |
| 📈 历史趋势 | 健康分历史曲线图 |
| ⏱️ 定时刷新 | 可配置 30s / 1m / 2m / 5m 自动刷新 |
| 🔔 飞书告警 | 健康分异常时自动推送飞书消息 |
| 🖥️ 开机自启 | launchd 服务，开机自动运行 |
| 📁 实时数据 | 每次刷新调用真实命令采集最新状态 |

## 快速开始

### 一键安装

```bash
cd ~/.openclaw/workspace-metapivot
bash scripts/install.sh
```

安装完成后：
- 服务自动启动
- 开机自动运行
- 全局命令 `workspace-health` 可用

### 命令行工具

```bash
workspace-health status      # 查看状态
workspace-health logs       # 查看日志
workspace-health test       # 发送测试告警
workspace-health restart    # 重启服务
workspace-health stop       # 停止服务
```

### 查看监控面板

```bash
open projects/workspace-health/dashboard.html
```

## 配置

### 飞书 Webhook

```bash
vim ~/.metapivot/secrets.env
# 或设置环境变量
export FEISHU_WEBHOOK_URL='https://open.feishu.cn/open-apis/bot/v2/hook/xxx'
```

### 服务参数

```bash
vim ~/.metapivot/config.env
```

可配置项：
- `COLLECTOR_INTERVAL`: 采集间隔（秒）
- `ALERT_THRESHOLD_CRITICAL`: 紧急告警阈值（默认 40）
- `ALERT_THRESHOLD_WARNING`: 警告告警阈值（默认 60）
- `FEISHU_NOTIFY_ENABLED`: 飞书通知开关

## 组件说明

### collector.sh
后台数据采集器，每分钟采集一次，写入 `data/latest.json`，并自动检查是否需要告警。

### alerter.sh
飞书 webhook 告警服务，支持重试和去重。

### dashboard.html
实时监控面板，浏览器打开即可。

### bin/workspace-health
命令行工具，提供 status/logs/test 等命令。

## 文件结构

```
.
├── scripts/
│   ├── install.sh              # 一键安装
│   ├── uninstall.sh            # 卸载
│   └── com.metapivot.workspace-health.plist  # launchd 配置
├── bin/
│   └── workspace-health        # 命令行工具
├── projects/workspace-health/
│   ├── collector.sh            # 数据采集器
│   ├── alerter.sh             # 告警服务
│   ├── dashboard.html          # 监控面板
│   └── data/
│       ├── latest.json         # 实时数据
│       ├── history/            # 历史数据
│       ├── alerts/             # 告警记录
│       └── logs/               # 服务日志
└── README.md
```

## 服务管理

```bash
# 查看服务状态
launchctl list | grep metapivot

# 手动启动
launchctl load ~/Library/LaunchAgents/com.metapivot.workspace-health.plist

# 手动停止
launchctl unload ~/Library/LaunchAgents/com.metapivot.workspace-health.plist

# 查看日志
tail -f projects/workspace-health/data/logs/collector.log
```

## 依赖

- macOS (使用 launchd)
- bash
- curl
- python3
- git
- vm_stat / df / uptime
