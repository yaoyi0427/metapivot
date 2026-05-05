# 元枢实战复盘

## 任务 #001: Workspace 健康仪表盘

### 遇到的问题

**1. bash heredoc 变量展开混乱**
- 问题：heredoc 中的 `${VAR}` 在 cat 时没有展开，导致 HTML 模板里全是原始变量名
- 原因：heredoc 默认不展开变量，需要用 `"EOF"` 而不是 `'EOF'`，但又会导致 `$()` 被执行
- 解决：把所有变量先计算好再放入 heredoc，确保 heredoc 内只有 `${已展开的变量}`
- 教训：复杂的 HTML 生成，用 Python 或先把数据都算出来再拼字符串

**2. gitignore 规则不完整**
- 问题：.gitignore 没有忽略 .DS_Store 和 data/，导致这些文件被跟踪
- 教训：新建项目时第一时间建 .gitignore，不要等 commit 了才发现

**3. report.html 是静态的，但需求暗示可能是动态的**
- 京哥问"是静态还是动态"，说明我应该在交付时说清楚技术实现
- 教训：技术选型要主动说明，不要等追问

---

## 任务 #002: 实时监控仪表盘

### 遇到的问题

**1. macOS top 命令输出格式不同**
- 问题：`top -l 1 | grep "PhysMem"` 输出 "15G used (2375M wired, 2685M compressor)"，不能直接提取百分比
- 解决：改用 `vm_stat` + `sysctl hw.memsize` 计算实际使用率
- 教训：macOS 工具链和 Linux 不同，跨平台脚本要实测验证

**2. bash history trim 命令兼容性问题**
- 问题：`head -n -100` 在 macOS BSD grep 不支持（Linux 的 head 支持负数）
- 解决：用 `ls -t ... | tail -n +101` 替代
- 教训：macOS 的命令行工具很多是 BSD 版本，和 Linux 有差异，写脚本要考虑到

**3. HTML 页面无法直接调用 exec**
- 问题：Dashboard 用纯前端 JS，无法直接执行系统命令
- 解决：拆分为 collector（后台 daemon）+ dashboard（前端读取 JSON）
- 教训：架构决策要基于技术约束，不是基于"应该是什么"

**4. collector 后台运行时无法捕获输出**
- 问题：后台运行时 `latest.json` 生成后立即 kill 进程，来不及验证
- 教训：daemon 调试要单步验证，先前台跑一次确认逻辑正确

---

## 任务 #003: 测试能力专项

### 遇到的问题

**1. 测试预期值写错**
- 问题：Test 8 预期 25 分，实际 0 分
- 原因：N/A branch 不加分，但 disk 90 >= 85 也不加分，我只算了 branch+disk
- 解决：重新理解评分逻辑，修正预期值
- 教训：测试的"正确"不是指"我觉得对"，而是指"和规格一致"

**2. macOS grep 不支持 -P (Perl regex)**
- 问题：test.sh 里用了 `grep -oP`，macOS grep 报错
- 解决：用 `awk` 替代 grep -P 做字符串提取
- 教训：工具链兼容性是 macOS 开发的基本素养

**3. 内存百分比解析**
- 之前遗留的问题，vm_stat 的字段分割要注意行尾特殊字符

---

## 核心教训总结

### 技术层面

1. **macOS != Linux** — 很多命令参数、输出格式不同，跨平台脚本要实测
2. **架构先行** — collector/dashboard 分离是正确决策，不是因为复杂，而是因为 HTML 无法调用 exec
3. **数据验证** — JSON 生成后用 `python3 -m json.tool` 验证格式
4. **Daemon 调试** — 先前台跑通，再后台运行

### 方法论层面

1. **测试覆盖要从第一行代码开始** — 不是事后补
2. **自我修正要及时** — 发现问题就修，不要等到 commit 后
3. **交付要完整** — README + 测试 + 文档，而不是"代码在里面你自己看"
4. **commit 要有原子性** — 一个 commit 只做一件事

### 沟通层面

1. **主动说明技术选型** — 不要等京哥追问
2. **识别隐含需求** — "实时监控"暗示需要后台采集，不是单次报告
3. **自我评估要诚实** — Level 4 中段，不是 Level 5
