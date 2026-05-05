# 🧠 元枢知识库

元枢的实战经验沉淀，从做题家到有经验的老手。

## 目录

- [复盘](RETROSPECTIVE.md) — 三个实战任务的遇到的问题、解决方案、教训
- [工具箱](TOOLBOX.md) — 常用命令、错误排查、架构模式

## 快速导航

### 遇到问题？
- [bash 常见错误](TOOLBOX.md#bash-脚本问题)
- [JSON 格式问题](TOOLBOX.md#json-问题)
- [Git 常见问题](TOOLBOX.md#git-问题)

### 想用某个命令？
- [Git 命令](TOOLBOX.md#git)
- [系统监控命令](TOOLBOX.md#系统监控-macos)
- [文件操作](TOOLBOX.md#文件操作)

### 不知道用什么架构？
- [Daemon + Frontend 分离](TOOLBOX.md#1-daemon--frontend-分离模式)
- [测试分层](TOOLBOX.md#2-测试分层模式)
- [健康评分模式](TOOLBOX.md#3-健康评分模式)

## 实战任务索引

| # | 任务 | 交付物 | 核心挑战 |
|---|------|--------|----------|
| 001 | Workspace 健康仪表盘 | report.html | bash heredoc + gitignore |
| 002 | 实时监控仪表盘 v2 | collector.sh + dashboard.html | macOS 兼容性 + 架构分离 |
| 003 | 测试能力专项 | tests/ | 测试覆盖 + macOS grep |
| (附加) | 元枢知识库 | metapivot-knowledge/ | 复盘 + 工具箱 |

## 核心教训

1. **macOS != Linux** — 工具链兼容性是基本素养
2. **架构先行** — 技术选型基于约束，不是"应该是什么"
3. **测试从第一天开始** — 不是事后补的
4. **交付要完整** — README + 测试 + 文档
5. **自我修正要及时** — 发现问题就修，不要等
