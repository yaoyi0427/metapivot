#!/bin/bash
# Workspace Health 一键卸载脚本
# 用法: bash scripts/uninstall.sh

WORKSPACE="$HOME/.openclaw/workspace-metapivot"
PLIST_NAME="com.metapivot.workspace-health.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
BIN_LINK="/usr/local/bin/workspace-health"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Workspace Health 卸载脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查是否安装
is_installed() {
    [ -f "$PLIST_DEST" ] && return 0 || return 1
}

is_running() {
    launchctl list | grep -q "com.metapivot.workspace-health" && return 0 || return 1
}

# 1. 停止服务
echo -e "${YELLOW}▶ 停止服务...${NC}"
if is_running; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    echo "  ✅ 服务已停止"
else
    echo "  ⚠️  服务未运行"
fi

# 2. 移除 plist
echo ""
echo -e "${YELLOW}▶ 移除 launchd 配置...${NC}"
if is_installed; then
    rm -f "$PLIST_DEST"
    echo "  ✅ launchd plist 已移除"
else
    echo "  ⚠️  launchd plist 不存在"
fi

# 3. 移除 bin 软链接
echo ""
echo -e "${YELLOW}▶ 移除全局命令...${NC}"
if [ -L "$BIN_LINK" ]; then
    rm -f "$BIN_LINK"
    echo "  ✅ 命令已移除"
else
    echo "  ⚠️  命令不存在"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 卸载完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "注意: 日志和数据文件保留在:"
echo "  $WORKSPACE/projects/workspace-health/data/"
echo ""
echo "如需完全清理，手动删除上述目录"
echo ""
