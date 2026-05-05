#!/bin/bash
# Workspace Health 一键安装脚本
# 用法: bash scripts/install.sh

set -e

WORKSPACE="$HOME/.openclaw/workspace-metapivot"
PLIST_NAME="com.metapivot.workspace-health.plist"
PLIST_SOURCE="$WORKSPACE/scripts/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
METAPIVOT_DIR="$HOME/.metapivot"
LOG_DIR="$WORKSPACE/projects/workspace-health/data/logs"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Workspace Health 安装脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查是否已安装
is_installed() {
    [ -f "$PLIST_DEST" ] && return 0 || return 1
}

is_running() {
    launchctl list | grep -q "com.metapivot.workspace-health" && return 0 || return 1
}

# 1. 创建必要目录
echo -e "${YELLOW}▶ 创建目录结构...${NC}"
mkdir -p "$LOG_DIR"
mkdir -p "$METAPIVOT_DIR"
echo "  ✅ 目录创建完成"

# 2. 设置权限
echo ""
echo -e "${YELLOW}▶ 设置权限...${NC}"

# metapivot 目录权限 700
chmod 700 "$METAPIVOT_DIR"
echo "  ✅ $METAPIVOT_DIR 权限设置为 700"

# secrets.env 权限 600
if [ -f "$METAPIVOT_DIR/secrets.env" ]; then
    chmod 600 "$METAPIVOT_DIR/secrets.env"
    echo "  ✅ secrets.env 权限设置为 600"
else
    echo -e "  ⚠️  secrets.env 不存在，请手动创建"
fi

# config.env 权限 600
if [ -f "$METAPIVOT_DIR/config.env" ]; then
    chmod 600 "$METAPIVOT_DIR/config.env"
    echo "  ✅ config.env 权限设置为 600"
fi

# 3. 复制 plist
echo ""
echo -e "${YELLOW}▶ 配置 launchd 服务...${NC}"

if is_installed; then
    echo "  ⚠️  服务已安装，先卸载..."
    bash "$WORKSPACE/scripts/uninstall.sh" > /dev/null 2>&1 || true
fi

# 复制 plist
cp "$PLIST_SOURCE" "$PLIST_DEST"
chmod 644 "$PLIST_DEST"
echo "  ✅ launchd plist 已配置"

# 4. 加载服务
echo ""
echo -e "${YELLOW}▶ 启动服务...${NC}"

if is_running; then
    echo "  ⚠️  服务已在运行，先停止..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

launchctl load "$PLIST_DEST"
echo "  ✅ 服务已启动"

# 5. 验证
echo ""
echo -e "${YELLOW}▶ 验证安装...${NC}"
sleep 2

if is_running; then
    echo -e "  ${GREEN}✅ 服务运行中${NC}"
else
    echo -e "  ${RED}❌ 服务启动失败${NC}"
    echo "  查看错误日志: workspace-health error-logs"
    exit 1
fi

# 检查日志
if [ -f "$LOG_DIR/collector.log" ]; then
    echo "  ✅ 日志文件正常"
else
    echo -e "  ${YELLOW}⚠️  日志文件尚未创建（等待采集）${NC}"
fi

# 6. 创建 bin 软链接
echo ""
echo -e "${YELLOW}▶ 创建全局命令...${NC}"
BIN_LINK="/usr/local/bin/workspace-health"
if [ -L "$BIN_LINK" ]; then
    rm "$BIN_LINK"
fi
ln -s "$WORKSPACE/bin/workspace-health" "$BIN_LINK"
echo "  ✅ 命令已创建: $BIN_LINK"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ 安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "使用方式:"
echo "  workspace-health status     # 查看状态"
echo "  workspace-health logs       # 查看日志"
echo "  workspace-health test       # 发送测试告警"
echo "  workspace-health stop       # 停止服务"
echo ""
echo "服务信息:"
echo "  Label: com.metapivot.workspace-health"
echo "  Plist: $PLIST_DEST"
echo ""
