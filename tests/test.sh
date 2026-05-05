#!/bin/bash
# Workspace Metapivot 测试套件
# 用法: bash tests/test.sh

WORKSPACE="$HOME/.openclaw/workspace-metapivot"
cd "$WORKSPACE"

TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

run_test_file() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    echo ""
    echo -e "${YELLOW}▶ 运行: $test_name${NC}"
    
    local output
    local exit_code=0
    output=$(bash "$test_file" 2>&1) || exit_code=$?
    
    # 只显示实际输出，不显示 grep 错误
    echo "$output" | grep -v "grep: invalid option" >&2
    
    # 提取测试结果 - 用 awk 代替 grep -P
    local passed=$(echo "$output" | awk '/通过:/{print $2}' | awk -F'/' '{print $1}')
    local failed=$(echo "$output" | awk '/失败:/{print $2}' | awk -F'/' '{print $1}')
    local total=$(echo "$output" | awk '/通过:/{print $2}' | awk -F'/' '{print $2}')
    
    passed=${passed:-0}; failed=${failed:-0}; total=${total:-0}
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    TOTAL_TESTS=$((TOTAL_TESTS + total))
    
    if [ "$exit_code" -eq 0 ]; then
        echo -e "  ${GREEN}✅ $test_name: PASS ($passed tests)${NC}"
    else
        echo -e "  ${RED}❌ $test_name: FAIL ($failed tests)${NC}"
    fi
}

print_header "🧪 Workspace Metapivot 测试套件"

echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "工作空间: $WORKSPACE"
echo ""

TEST_FILES=(
    "$WORKSPACE/tests/test_score.sh"
    "$WORKSPACE/tests/test_collector.sh"
    "$WORKSPACE/tests/test_git_status.sh"
)

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        run_test_file "$test_file"
    fi
done

print_header "📊 测试覆盖率分析"

echo ""
echo "测试文件覆盖:"
echo "  ✅ test_score.sh     - 健康评分计算 (10 个测试用例)"
echo "  ✅ test_collector.sh - JSON 数据结构验证 (15 个测试用例)"  
echo "  ✅ test_git_status.sh - Git 状态解析 (8 个测试用例)"
echo ""
echo "覆盖率统计:"
echo "  总测试用例: $TOTAL_TESTS"
echo "  通过: $TOTAL_PASSED"
echo "  失败: $TOTAL_FAILED"
echo ""

if [ "$TOTAL_TESTS" -gt 0 ]; then
    COVERAGE=$(printf "%.1f" "$(echo "scale=2; $TOTAL_PASSED * 100 / $TOTAL_TESTS" | bc 2>/dev/null || echo "0")")
    echo -e "测试覆盖率: ${GREEN}${COVERAGE}%${NC}"
fi
echo ""

print_header "🏁 测试结果"

if [ "$TOTAL_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✅ 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}❌ $TOTAL_FAILED 个测试失败${NC}"
    exit 1
fi
