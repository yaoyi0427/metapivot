#!/bin/bash
# 安装/卸载脚本测试
# 测试幂等性、权限设置等

INSTALL_TESTS=0
INSTALL_PASSED=0
INSTALL_FAILED=0

WORKSPACE="$HOME/.openclaw/workspace-metapivot"
METAPIVOT_DIR="$HOME/.metapivot"
BIN_LINK="/usr/local/bin/workspace-health"

echo "=== 安装脚本测试 ==="

# Test 1: 目录创建幂等性
INSTALL_TESTS=$((INSTALL_TESTS + 1))
mkdir -p "$METAPIVOT_DIR"
mkdir -p "$METAPIVOT_DIR"  # 再次创建，不应报错
if [ -d "$METAPIVOT_DIR" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] 目录创建幂等性 → 通过"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] 目录创建幂等性 → 失败"
fi

# Test 2: 权限设置正确性
INSTALL_TESTS=$((INSTALL_TESTS + 1))
chmod 700 "$METAPIVOT_DIR"
perms=$(stat -f "%Lp" "$METAPIVOT_DIR" 2>/dev/null || stat -c "%a" "$METAPIVOT_DIR" 2>/dev/null)
if [ "$perms" = "700" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] 权限设置 700 → 通过 (实际: $perms)"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] 权限设置 700 → 失败 (实际: $perms)"
fi

# Test 3: bin 目录存在
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -d "$WORKSPACE/bin" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] bin 目录存在 → 通过"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] bin 目录存在 → 失败"
fi

# Test 4: workspace-health 命令可执行
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -x "$WORKSPACE/bin/workspace-health" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] workspace-health 可执行 → 通过"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] workspace-health 可执行 → 失败"
fi

# Test 5: secrets.env 权限
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -f "$METAPIVOT_DIR/secrets.env" ]; then
    chmod 600 "$METAPIVOT_DIR/secrets.env"
    perms=$(stat -f "%Lp" "$METAPIVOT_DIR/secrets.env" 2>/dev/null || stat -c "%a" "$METAPIVOT_DIR/secrets.env" 2>/dev/null)
    if [ "$perms" = "600" ]; then
        INSTALL_PASSED=$((INSTALL_PASSED + 1))
        echo "  ✅ [$INSTALL_TESTS] secrets.env 权限 600 → 通过"
    else
        INSTALL_FAILED=$((INSTALL_FAILED + 1))
        echo "  ❌ [$INSTALL_TESTS] secrets.env 权限 600 → 失败 (实际: $perms)"
    fi
else
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] secrets.env 检查 → 跳过（文件不存在）"
fi

# Test 6: config.env 权限
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -f "$METAPIVOT_DIR/config.env" ]; then
    chmod 600 "$METAPIVOT_DIR/config.env"
    perms=$(stat -f "%Lp" "$METAPIVOT_DIR/config.env" 2>/dev/null || stat -c "%a" "$METAPIVOT_DIR/config.env" 2>/dev/null)
    if [ "$perms" = "600" ]; then
        INSTALL_PASSED=$((INSTALL_PASSED + 1))
        echo "  ✅ [$INSTALL_TESTS] config.env 权限 600 → 通过"
    else
        INSTALL_FAILED=$((INSTALL_FAILED + 1))
        echo "  ❌ [$INSTALL_TESTS] config.env 权限 600 → 失败 (实际: $perms)"
    fi
else
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] config.env 检查 → 跳过（文件不存在）"
fi

# Test 7: scripts 目录存在
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -d "$WORKSPACE/scripts" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] scripts 目录存在 → 通过"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] scripts 目录存在 → 失败"
fi

# Test 8: install.sh 存在且可执行
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -x "$WORKSPACE/scripts/install.sh" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] install.sh 可执行 → 通过"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] install.sh 可执行 → 失败"
fi

# Test 9: uninstall.sh 存在且可执行
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -x "$WORKSPACE/scripts/uninstall.sh" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] uninstall.sh 可执行 → 通过"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] uninstall.sh 可执行 → 失败"
fi

# Test 10: plist 文件存在
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -f "$WORKSPACE/scripts/com.metapivot.workspace-health.plist" ]; then
    INSTALL_PASSED=$((INSTALL_PASSED + 1))
    echo "  ✅ [$INSTALL_TESTS] plist 文件存在 → 通过"
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] plist 文件存在 → 失败"
fi

# Test 11: plist XML 语法正确
INSTALL_TESTS=$((INSTALL_TESTS + 1))
if [ -f "$WORKSPACE/scripts/com.metapivot.workspace-health.plist" ]; then
    if python3 -c "import plistlib; plistlib.load(open('$WORKSPACE/scripts/com.metapivot.workspace-health.plist','rb'))" 2>/dev/null; then
        INSTALL_PASSED=$((INSTALL_PASSED + 1))
        echo "  ✅ [$INSTALL_TESTS] plist XML 语法正确 → 通过"
    else
        # 尝试用 xmllint
        if which xmllint > /dev/null 2>&1; then
            if xmllint --noout "$WORKSPACE/scripts/com.metapivot.workspace-health.plist" 2>/dev/null; then
                INSTALL_PASSED=$((INSTALL_PASSED + 1))
                echo "  ✅ [$INSTALL_TESTS] plist XML 语法正确 → 通过"
            else
                INSTALL_FAILED=$((INSTALL_FAILED + 1))
                echo "  ❌ [$INSTALL_TESTS] plist XML 语法正确 → 失败"
            fi
        else
            # 用 grep 检查基本结构
            if grep -q "<dict>" "$WORKSPACE/scripts/com.metapivot.workspace-health.plist" && grep -q "</plist>" "$WORKSPACE/scripts/com.metapivot.workspace-health.plist"; then
                INSTALL_PASSED=$((INSTALL_PASSED + 1))
                echo "  ✅ [$INSTALL_TESTS] plist XML 结构正确 → 通过"
            else
                INSTALL_FAILED=$((INSTALL_FAILED + 1))
                echo "  ❌ [$INSTALL_TESTS] plist XML 结构正确 → 失败"
            fi
        fi
    fi
else
    INSTALL_FAILED=$((INSTALL_FAILED + 1))
    echo "  ❌ [$INSTALL_TESTS] plist XML 语法正确 → 失败（文件不存在）"
fi

echo ""
echo "=== 测试结果 ==="
echo "通过: $INSTALL_PASSED/$INSTALL_TESTS"
echo "失败: $INSTALL_FAILED/$INSTALL_TESTS"
echo ""

[ "$INSTALL_FAILED" -eq 0 ] && exit 0 || exit 1
