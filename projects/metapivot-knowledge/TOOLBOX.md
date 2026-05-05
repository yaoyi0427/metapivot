# 元枢工具箱

## 常用命令备忘

### Git
```bash
# 查看当前状态
git status --short

# 查看最近 commit
git log --oneline -3

# 查看分支
git branch --show-current

# 查看 remote
git remote -v

# 查看 ahead/behind
git rev-list --left-only --count HEAD...@{upstream}

# 强制更新 remote 追踪
git fetch origin
```

### 系统监控 (macOS)
```bash
# CPU 负载
uptime | awk -F'load averages:' '{print $2}'

# 内存使用率（正确方式）
vm_stat
# 计算: (Active + Wired + Compressor) / Total Pages * 100

# 磁盘使用
df -h ~

# 总内存
sysctl -n hw.memsize
```

### 文件操作
```bash
# 查找修改过的文件
find . -name "*.md" -mtime -1

# JSON 格式化验证
python3 -m json.tool file.json

# 创建带时间的备份
cp file file.$(date +%Y%m%d_%H%M%S)
```

### 进程管理
```bash
# 查看后台任务
jobs

# 后台运行脚本
nohup bash script.sh > output.log 2>&1 &

# 杀掉包含关键字的进程
pkill -f "collector.sh"
```

---

## 常见错误排查

### bash 脚本问题

**Q: "bad math expression" 错误**
- 原因：变量为空或包含非数字字符
- 排查：`set -x` 调试模式运行
- 解决：`${VAR:-0}` 提供默认值

**Q: macOS grep 不支持 -P**
- 原因：macOS grep 是 BSD 版本
- 解决：用 `grep -E` 或 `awk` 替代 Perl regex

**Q: head -n -100 不支持**
- 原因：macOS head 不支持负数
- 解决：`ls -t ... | tail -n +101`

**Q: 变量在 heredoc 里没有展开**
- 原因：heredoc 用的是 `'EOF'` 而不是 `"EOF"`
- 解决：需要展开用 `"EOF"`，或者先计算所有变量

### JSON 问题

**Q: JSON 格式错误**
- 解决：`python3 -m json.tool file.json` 验证
- 注意：中文和特殊字符需要转义

**Q: JSON 里有换行符**
- 原因：commit message 可能包含换行
- 解决：sed 替换 `s/\n/\\n/g`

### Git 问题

**Q: git add 报错 "did not match any files"**
- 原因：文件路径写错了，或者在错误的目录
- 解决：`pwd && ls` 确认当前位置

**Q: "nothing to commit, working tree clean" 但实际有更改**
- 原因：文件在 .gitignore 里
- 解决：`git status --ignored` 确认

---

## 架构模式

### 1. Daemon + Frontend 分离模式

**适用场景**：需要持续采集数据，但前端无法直接调用系统命令

**结构**：
```
collector.sh (后台 daemon) → data/latest.json
dashboard.html (前端，读取 JSON)
```

**关键点**：
- collector 负责数据采集和持久化
- dashboard 只负责展示，不做数据处理
- 两者通过文件系统（JSON）解耦

### 2. 测试分层模式

**结构**：
```
test.sh (测试运行器)
├── test_score.sh (单元测试)
├── test_collector.sh (数据结构测试)
└── test_git_status.sh (集成测试)
```

**原则**：
- 单元测试：纯逻辑，无外部依赖
- 数据结构测试：验证输出格式
- 集成测试：调用真实命令，验证真实行为

### 3. 健康评分模式

**维度权重**：
```
总分 100 = 安全(20) + 配置(20) + 性能(30) + 同步(10) + 监控(10) + 自检(10)
```

**评分逻辑**：
- 每项有明确的通过/不通过条件
- 分数 = 通过项权重之和
- 异常状态要醒目告警

### 4. 配置文件驱动模式

**结构**：
```
SOUL.md      → 价值观
AGENTS.md    → 工作方法
IDENTITY.md  → 身份定义
MEMORY.md    → 长期记忆
```

**原则**：
- 每份文件职责单一
- 启动时加载，变更时更新
- 不在代码里硬编码
