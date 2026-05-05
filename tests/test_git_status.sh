#!/bin/bash
# Git 状态解析测试

GIT_TESTS=0
GIT_PASSED=0
GIT_FAILED=0

echo "=== Git 状态解析测试 ==="

# Test: clean status detection
parse_git_clean() {
    local status_output="$1"
    if [ -z "$status_output" ]; then
        echo 1
    else
        echo 0
    fi
}

# Test cases
test_clean_detection() {
    local input="$1"
    local expected="$2"
    GIT_TESTS=$((GIT_TESTS + 1))
    result=$(parse_git_clean "$input")
    if [ "$result" -eq "$expected" ]; then
        GIT_PASSED=$((GIT_PASSED + 1))
        echo "  ✅ [$GIT_TESTS] clean detection: '$input' → $result"
    else
        GIT_FAILED=$((GIT_FAILED + 1))
        echo "  ❌ [$GIT_TESTS] clean detection: '$input' → $result (expected $expected)"
    fi
}

test_clean_detection "" 1          # 空 = 干净
test_clean_detection "?? file" 0   # untracked = 不干净
test_clean_detection " M file" 0   # modified = 不干净
test_clean_detection "A  file" 0   # staged = 不干净
test_clean_detection " D file" 0   # deleted = 不干净

# Test: branch name extraction
GIT_TESTS=$((GIT_TESTS + 1))
branch=$(git branch --show-current 2>/dev/null || echo "N/A")
if [ -n "$branch" ] && [ "$branch" != "" ]; then
    GIT_PASSED=$((GIT_PASSED + 1))
    echo "  ✅ [$GIT_TESTS] branch name valid: '$branch'"
else
    GIT_FAILED=$((GIT_FAILED + 1))
    echo "  ❌ [$GIT_TESTS] branch name invalid: '$branch'"
fi

# Test: remote detection
GIT_TESTS=$((GIT_TESTS + 1))
if git remote -v 2>/dev/null | grep -q 'github.com'; then
    GIT_PASSED=$((GIT_PASSED + 1))
    echo "  ✅ [$GIT_TESTS] remote github.com detected"
else
    GIT_FAILED=$((GIT_FAILED + 1))
    echo "  ❌ [$GIT_TESTS] remote github.com not found"
fi

# Test: last commit info
GIT_TESTS=$((GIT_TESTS + 1))
commit=$(git log -1 --format="%H|%ae|%ai|%s" 2>/dev/null)
if echo "$commit" | grep -q '|'; then
    GIT_PASSED=$((GIT_PASSED + 1))
    msg=$(echo "$commit" | cut -d'|' -f4 | cut -c1-50)
    echo "  ✅ [$GIT_TESTS] last commit info: $msg..."
else
    GIT_FAILED=$((GIT_FAILED + 1))
    echo "  ❌ [$GIT_TESTS] last commit info invalid"
fi

echo ""
echo "=== 测试结果 ==="
echo "通过: $GIT_PASSED/$GIT_TESTS"
echo "失败: $GIT_FAILED/$GIT_TESTS"
echo ""

[ "$GIT_FAILED" -eq 0 ] && exit 0 || exit 1
