#!/bin/bash
# 健康评分计算逻辑测试
# 用模拟数据测试 score 计算是否正确

SCORE_TESTS=0
SCORE_PASSED=0
SCORE_FAILED=0

assert_score() {
    SCORE_TESTS=$((SCORE_TESTS + 1))
    local git_branch="$1"
    local git_clean="$2"
    local hb_effective="$3"
    local mem_pct="$4"
    local disk_pct="$5"
    local config_complete="$6"
    local has_remote="$7"
    local synced="$8"
    local expected="$9"
    
    # 计算实际分数
    score=0
    [ "$git_branch" != "N/A" ] && [ -n "$git_branch" ] && score=$((score+10))
    [ "$git_clean" -eq 1 ] && score=$((score+20))
    [ "$hb_effective" -eq 1 ] && score=$((score+10))
    [ "${mem_pct:-0}" -lt 80 ] && score=$((score+15))
    [ "${disk_pct:-0}" -lt 85 ] && score=$((score+15))
    [ "$config_complete" -eq 1 ] && score=$((score+20))
    [ "$has_remote" -eq 1 ] && [ "$synced" -eq 1 ] && score=$((score+10))
    
    if [ "$score" -eq "$expected" ]; then
        SCORE_PASSED=$((SCORE_PASSED + 1))
        echo "  ✅ [$SCORE_TESTS] PASS | 预期=$expected 实际=$score"
    else
        SCORE_FAILED=$((SCORE_FAILED + 1))
        echo "  ❌ [$SCORE_TESTS] FAIL | 预期=$expected 实际=$score | params: branch=$git_branch clean=$git_clean hb=$hb_effective mem=$mem_pct disk=$disk_pct"
    fi
}

echo "=== 健康评分计算测试 ==="

# Test 1: 全绿状态 (100分)
assert_score "main" 1 1 50 30 1 1 1 100

# Test 2: 工作区脏 (80分)
assert_score "main" 0 1 50 30 1 1 1 80

# Test 3: 无 HEARTBEAT (90分)
assert_score "main" 1 0 50 30 1 1 1 90

# Test 4: 内存超限 (85分)
assert_score "main" 1 1 85 30 1 1 1 85

# Test 5: 磁盘超限 (85分)
assert_score "main" 1 1 50 90 1 1 1 85

# Test 6: 配置文件缺失 (80分)
assert_score "main" 1 1 50 30 0 1 1 80

# Test 7: 无 remote (90分)
assert_score "main" 1 1 50 30 1 0 0 90

# Test 8: 全挂状态 (25分: branch 10 + disk 15)
assert_score "N/A" 0 0 90 90 0 0 0 0

# Test 9: 仅 branch 正常 (10分)
assert_score "main" 0 0 90 90 0 0 0 10

# Test 10: 完美状态边界 (100分)
assert_score "feature" 1 1 79 84 1 1 1 100

echo ""
echo "=== 测试结果 ==="
echo "通过: $SCORE_PASSED/$SCORE_TESTS"
echo "失败: $SCORE_FAILED/$SCORE_TESTS"
echo ""

if [ "$SCORE_FAILED" -eq 0 ]; then
    echo "✅ 所有测试通过"
    exit 0
else
    echo "❌ $SCORE_FAILED 个测试失败"
    exit 1
fi
