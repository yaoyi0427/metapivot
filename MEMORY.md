# MEMORY.md - 元枢的长期记忆

## 身份定义
- 我是：元枢 ⚡ AI Coding Agent
- 我的使命：成为全球第一的 AI Coding Agent
- 我的导师：京哥

## 关于京哥
- 名字：京哥
- 时区：Asia/Shanghai (GMT+8)
- 详见：USER.md（待持续更新）

## 已掌握的核心技能

### 工具链
- **Git** — branch/status/log/commit/push，已能熟练处理 .gitignore 和多文件 commit
- **bash** — 脚本编写、daemon 后台运行、管道组合
- **macOS 系统命令** — vm_stat、df、uptime、top 等（注意和 Linux 的差异）
- **Python** — JSON 验证、文件处理、字符串操作
- **HTML/CSS/JS** — Canvas 图表、无依赖前端实现
- **curl + webhook** — 飞书机器人通知、HTTP API 调用 — branch/status/log/commit/push，已能熟练处理 .gitignore 和多文件 commit
- **bash** — 脚本编写、daemon 后台运行、管道组合
- **macOS 系统命令** — vm_stat、df、uptime、top 等（注意和 Linux 的差异）
- **Python** — JSON 验证、文件处理、字符串操作
- **HTML/CSS/JS** — Canvas 图表、无依赖前端实现

### 测试能力
- 测试分层：单元测试 / 数据结构测试 / 集成测试
- `bash tests/test.sh` 本地运行全量测试
- 覆盖率 100%（33/33 测试用例）

### 架构思维
- **Daemon + Frontend 分离** — 当前端无法调用 exec 时的正确架构决策
- 健康评分 7 维度量化评估
- 通过 JSON 文件解耦数据采集和展示层

## 踩过的坑 & 教训

### bash heredoc 变量展开
- 问题：heredoc 里 `${VAR}` 没有展开
- 原因：用 `'EOF'` 而不是 `"EOF"`，或者 heredoc 内嵌套了未展开的变量
- 避免：所有变量先计算完再放入 heredoc，或用 Python 生成复杂 HTML

### macOS grep -P 不支持
- 问题：`grep -oP` 在 macOS 报 invalid option
- 解决：用 `awk` 或 `grep -E` 替代 Perl regex
- 避免：跨平台脚本避免使用 GNU-only 的参数

### macOS head -n -100 不支持
- 问题：BSD head 不支持负数（只支持正数）
- 解决：`ls -t ... | tail -n +101` 替代
- 避免：macOS 开发用 BSD 工具链，和 Linux 有差异

### macOS curl HTTP 状态码
- 问题：curl -w 输出格式处理（分离响应体和状态码）
- 解决：用 `tail -1` 取状态码，其余为响应体
- 避免：HTTP 调用后要正确分离响应和状态码

### macOS top 输出格式
- 问题：`top -l 1 | grep PhysMem` 输出 "15G used" 不是百分比
- 解决：改用 `vm_stat + sysctl hw.memsize` 计算
- 避免：macOS 系统命令要实测，不能假设和 Linux 一致

### gitignore 遗漏
- 问题：.DS_Store 和 data/ 没有忽略，被跟踪了
- 教训：新建项目第一时间建 .gitignore
- 避免：创建目录结构时就规划好 ignore 规则

### 测试预期值写错
- 问题：Test 8 预期 25 分实际 0 分
- 原因：没有正确理解评分逻辑就写预期
- 教训：测试的"正确" = 和规格一致，不是"我觉得对"

## 重要决策记录

### 001: 单次报告 → 实时监控的架构选择
- 背景：Dashboard HTML 无法调用 exec，但需要"实时"刷新
- 选项 A：纯前端轮询（不可行，JS 不能执行系统命令）
- 选项 B：collector daemon + dashboard 前端（可行）
- 选择：B
- 理由：架构约束决定技术选型，不是偏好

### 002: data/ 目录 gitignore
- 背景：运行时数据（latest.json、history/）不应进入 git
- 选择：.gitignore 添加 `projects/workspace-health/data/` + 从已跟踪文件中移除
- 教训：运行时数据必须隔离，防止污染 git 状态

### 003: 外部服务集成的架构选择
- 背景：需要向京哥推送飞书告警，但不能把 Webhook URL 硬编码
- 选项 A：直接硬编码 URL（不安全）
- 选项 B：环境变量注入（可行但不持久）
- 选项 C：secrets.env 文件管理（持久且安全）
- 选择：C（~/.metapivot/secrets.env）
- 教训：secrets 绝不硬编码，用独立配置文件管理
- 背景：运行时数据（latest.json、history/）不应进入 git
- 选择：.gitignore 添加 `projects/workspace-health/data/` + 从已跟踪文件中移除
- 教训：运行时数据必须隔离，防止污染 git 状态

## 工作空间
- 路径：~/.openclaw/workspace-metapivot
- 操作系统：Darwin (macOS)
- 工具链：Git / Node.js / Python3 / OpenClaw 内置命令
- GitHub: https://github.com/yaoyi0427/metapivot

## 成长轨迹

| 阶段 | 内容 | 状态 |
|------|------|------|
| Level 1-3 | 配置文件建立（IDENTITY/SOUL/AGENTS/MEMORY/HEARTBEAT/TOOLS） | ✅ 完成 |
| Level 4 (#001) | Workspace 健康仪表盘（bash + HTML） | ✅ 完成 |
| Level 4 (#002) | 实时监控仪表盘（collector daemon + dashboard） | ✅ 完成 |
| Level 4 (#003) | 测试能力专项（33 测试用例，100% 覆盖） | ✅ 完成 |
| Level 4 (附加) | 元枢知识库（复盘 + 工具箱） | ✅ 完成 |
| Level 4 (#004) | 飞书 webhook 通知服务（alerter.sh） | ✅ 完成 |

## Level 评估
- 当前：Level 4 末段 ✅
- 目标：Level 5（独立服务化）
- 已掌握：外部 API 调用、secrets 管理、网络异常处理、重试机制
