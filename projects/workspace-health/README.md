# 🫀 Workspace 实时监控仪表盘

> v2 — 从"单次报告"升级为"持续监控"

## 功能

| 功能 | 说明 |
|------|------|
| 📊 健康评分 | 0-100 分，7 项评分维度 |
| 📈 历史趋势 | 健康分历史曲线图 |
| ⏱️ 定时刷新 | 可配置 30s / 1m / 2m / 5m 自动刷新 |
| 🔔 异常告警 | 分 < 60 或关键指标异常时醒目提示 |
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

## 运行方式

### 1. 启动数据采集器（后台持续运行）

```bash
cd ~/.openclaw/workspace-metapivot
bash projects/workspace-health/collector.sh
```

可指定采集间隔（秒）：
```bash
bash projects/workspace-health/collector.sh 30
```

### 2. 打开监控面板

直接在浏览器打开 HTML 文件：

```bash
# macOS
open projects/workspace-health/dashboard.html

# 或者获取路径
realpath projects/workspace-health/dashboard.html
```

然后用浏览器打开该路径即可。

### 3. 可选：手动生成单次报告

```bash
bash projects/workspace-health/workspace-health.sh
open projects/workspace-health/report.html
```

## 文件结构

```
projects/workspace-health/
├── collector.sh          # 后台数据采集器（daemon）
├── workspace-health.sh    # 单次报告生成器
├── dashboard.html        # 实时监控面板（浏览器打开）
├── report.html           # 单次报告输出
├── data/                 # 数据目录
│   ├── latest.json       # 最新数据
│   └── history/          # 历史数据（JSON）
└── README.md
```

## 数据来源

| 命令 | 用途 |
|------|------|
| `git branch --show-current` | 当前分支 |
| `git status --porcelain` | 未提交更改 |
| `git log -1` | 最近 commit |
| `git remote -v` | Remote 检测 |
| `df -h` | 磁盘使用 |
| `uptime` | CPU 负载 |
| `top -l 1` | 内存信息 |

## 技术实现

- **前端**：纯 HTML + CSS + JS，无框架依赖
- **图表**：Canvas API 原生绘制
- **数据**：JSON 文件存储，页面直接读取
- **刷新**：页面 JS 定时器 + 可配置间隔
- **历史**：保留最近 100 条采集记录

## 使用场景

- 长时间运行监控，随时掌握 workspace 健康状态
- 配合 cron 或 terminal 多窗口使用
- 作为 Agent 自我健康检查的可视化入口
