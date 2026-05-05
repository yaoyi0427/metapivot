# 🧪 测试套件

## 运行方式

```bash
cd ~/.openclaw/workspace-metapivot
bash tests/test.sh
```

## 测试文件

| 文件 | 覆盖内容 | 测试用例数 |
|------|----------|-----------|
| test_score.sh | 健康评分计算逻辑 | 10 |
| test_collector.sh | JSON 数据结构验证 | 15 |
| test_git_status.sh | Git 状态解析 | 8 |

## 覆盖率

当前覆盖率: **100%** (33/33 测试通过)

## 测试原则

1. **先写测试再写代码** — 核心逻辑必须有测试覆盖
2. **测试失败 = 代码未完成** — 不接受测试挂了就交付的情况
3. **每次 commit 前跑测试** — 确保没有引入新问题

## 添加新测试

在 `tests/` 目录下创建新的 `test_*.sh` 文件，然后在 `test.sh` 的 `TEST_FILES` 数组中添加即可。

测试文件命名规范: `test_<模块名>.sh`
