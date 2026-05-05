# 🛠️ Workspace 健康仪表盘

监控 workspace 的健康状态，让问题在发生前就被发现。

## 功能

| 模块 | 监控内容 |
|------|----------|
| 📊 Git 状态 | 分支、未提交更改、sync 状态、最近 commit |
| 📁 配置文件 | 七份核心文件是否完整 |
| 🧠 Memory | memory/ 目录文件及最后修改时间 |
| 💻 系统资源 | CPU 负载、内存、磁盘使用、运行时长 |
| 💓 HEARTBEAT | 心跳配置是否合规 |

## 运行方式

```bash
# 进入 workspace
cd ~/.openclaw/workspace-metapivot

# 运行脚本
bash projects/workspace-health/workspace-health.sh

# 查看报告
open projects/workspace-health/report.html
# 或
cat projects/workspace-health/report.html
```

## 技术实现

- 数据来源：纯 exec 调用真实命令（git、stat、df、uptime 等）
- 输出格式：可读的 HTML 页面
- 无外部依赖，纯 bash 脚本

## 文件结构

```
projects/workspace-health/
├── workspace-health.sh   # 数据采集脚本
├── report.html          # 生成的报告（可浏览器打开）
└── README.md            # 本文件
```

## 数据来源

| 命令 | 用途 |
|------|------|
| `git branch --show-current` | 当前分支 |
| `git status --porcelain` | 未提交更改 |
| `git log -1` | 最近 commit |
| `git rev-list --count` | ahead/behind 数量 |
| `stat -f "%Sm"` | 文件修改时间 |
| `df -h` | 磁盘使用 |
| `uptime` | CPU 负载、运行时长 |
| `vm_stat / top` | 内存信息 |
