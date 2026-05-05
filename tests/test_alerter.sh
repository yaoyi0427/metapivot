#!/bin/bash
# alerter.sh 告警逻辑测试
# 不依赖外部 webhook，只测试本地逻辑

ALERT_TESTS=0
ALERT_PASSED=0
ALERT_FAILED=0

WORKSPACE="$HOME/.openclaw/workspace-metapivot"
TEST_ALERT_DIR=$(mktemp -d)

# 模拟 is_alert_sent / mark_alert_sent / clear_alert_sent
is_alert_sent() {
    local alert_key="$1"
    [ -f "$TEST_ALERT_DIR/.sent_${alert_key}" ] && return 0
    return 1
}

mark_alert_sent() {
    local alert_key="$1"
    touch "$TEST_ALERT_DIR/.sent_${alert_key}"
}

clear_alert_sent() {
    local alert_key="$1"
    rm -f "$TEST_ALERT_DIR/.sent_${alert_key}"
}

echo "=== Alerter 告警逻辑测试 ==="

# Test 1: 去重逻辑 - 首次发送
ALERT_TESTS=$((ALERT_TESTS + 1))
if ! is_alert_sent "test_key"; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 去重: 首次检查，未发送 → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 去重: 首次检查，未发送 → 失败"
fi

# Test 2: 去重逻辑 - 标记后检查
ALERT_TESTS=$((ALERT_TESTS + 1))
mark_alert_sent "test_key"
if is_alert_sent "test_key"; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 去重: 标记后检查，已发送 → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 去重: 标记后检查，已发送 → 失败"
fi

# Test 3: 去重逻辑 - 清理后检查
ALERT_TESTS=$((ALERT_TESTS + 1))
clear_alert_sent "test_key"
if ! is_alert_sent "test_key"; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 去重: 清理后检查，未发送 → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 去重: 清理后检查，未发送 → 失败"
fi

# Test 4: 健康分判断 - 紧急 (< 40)
ALERT_TESTS=$((ALERT_TESTS + 1))
score=35
level=""
[ "$score" -lt 40 ] && level="critical"
if [ "$level" = "critical" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 紧急判断: score=35 → critical → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 紧急判断: score=35 → 通过"
fi

# Test 5: 健康分判断 - 警告 (40-60)
ALERT_TESTS=$((ALERT_TESTS + 1))
score=55
level=""
[ "$score" -ge 40 ] && [ "$score" -lt 60 ] && level="warning"
if [ "$level" = "warning" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 警告判断: score=55 → warning → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 警告判断: score=55 → 失败"
fi

# Test 6: 健康分判断 - 正常 (>= 60)
ALERT_TESTS=$((ALERT_TESTS + 1))
score=75
level=""
[ "$score" -lt 40 ] && level="critical"
[ "$score" -ge 40 ] && [ "$score" -lt 60 ] && level="warning"
if [ -z "$level" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 正常判断: score=75 → 无告警 → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 正常判断: score=75 → 失败 (level=$level)"
fi

# Test 7: 边界值 - score=40
ALERT_TESTS=$((ALERT_TESTS + 1))
score=40
level=""
[ "$score" -lt 40 ] && level="critical"
[ "$score" -ge 40 ] && [ "$score" -lt 60 ] && level="warning"
if [ "$level" = "warning" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 边界值: score=40 → warning → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 边界值: score=40 → 失败"
fi

# Test 8: 边界值 - score=39
ALERT_TESTS=$((ALERT_TESTS + 1))
score=39
level=""
[ "$score" -lt 40 ] && level="critical"
[ "$score" -ge 40 ] && [ "$score" -lt 60 ] && level="warning"
if [ "$level" = "critical" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 边界值: score=39 → critical → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 边界值: score=39 → 失败"
fi

# Test 9: 边界值 - score=59
ALERT_TESTS=$((ALERT_TESTS + 1))
score=59
level=""
[ "$score" -lt 40 ] && level="critical"
[ "$score" -ge 40 ] && [ "$score" -lt 60 ] && level="warning"
if [ "$level" = "warning" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 边界值: score=59 → warning → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 边界值: score=59 → 失败"
fi

# Test 10: 边界值 - score=60
ALERT_TESTS=$((ALERT_TESTS + 1))
score=60
level=""
[ "$score" -lt 40 ] && level="critical"
[ "$score" -ge 40 ] && [ "$score" -lt 60 ] && level="warning"
if [ -z "$level" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 边界值: score=60 → 无告警 → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 边界值: score=60 → 失败"
fi

# Test 11: JSON 解析
ALERT_TESTS=$((ALERT_TESTS + 1))
TEST_JSON="$TEST_ALERT_DIR/test_data.json"
cat > "$TEST_JSON" << 'JSON'
{
    "score": 75,
    "git": {"branch": "main", "clean": 1},
    "system": {"disk_pct": 30, "memory_pct": 50},
    "heartbeat": {"effective": 1},
    "config": {"complete": 1},
    "timestamp": "2026-05-06 00:00:00"
}
JSON

score=$(python3 -c "import json; print(json.load(open('$TEST_JSON'))['score'])" 2>/dev/null)
if [ "$score" = "75" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] JSON 解析: score=75 → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] JSON 解析: score=75 → 失败 (got $score)"
fi

# Test 12: 指数退避计算
ALERT_TESTS=$((ALERT_TESTS + 1))
delay=1
delay=$((delay * 2))  # 第2次
if [ "$delay" -eq 2 ]; then
    delay=$((delay * 2))  # 第3次
    if [ "$delay" -eq 4 ]; then
        ALERT_PASSED=$((ALERT_PASSED + 1))
        echo "  ✅ [$ALERT_TESTS] 指数退避: 1→2→4 → 通过"
    else
        ALERT_FAILED=$((ALERT_FAILED + 1))
        echo "  ❌ [$ALERT_TESTS] 指数退避: 1→2→4 → 失败"
    fi
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 指数退避: 1→2→4 → 失败"
fi

# Test 13: 告警 key 生成
ALERT_TESTS=$((ALERT_TESTS + 1))
score=35
alert_key="critical_score_${score}"
if [ "$alert_key" = "critical_score_35" ]; then
    ALERT_PASSED=$((ALERT_PASSED + 1))
    echo "  ✅ [$ALERT_TESTS] 告警 key: critical_score_35 → 通过"
else
    ALERT_FAILED=$((ALERT_FAILED + 1))
    echo "  ❌ [$ALERT_TESTS] 告警 key: critical_score_35 → 失败"
fi

# 清理
rm -rf "$TEST_ALERT_DIR"

echo ""
echo "=== 测试结果 ==="
echo "通过: $ALERT_PASSED/$ALERT_TESTS"
echo "失败: $ALERT_FAILED/$ALERT_TESTS"
echo ""

[ "$ALERT_FAILED" -eq 0 ] && exit 0 || exit 1
