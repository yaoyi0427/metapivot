#!/bin/bash
# Workspace Health Dashboard - Data Collector
# 调用真实命令采集 workspace 健康数据

WORKSPACE="$HOME/.openclaw/workspace-metapivot"
OUTPUT="$WORKSPACE/projects/workspace-health/report.html"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "正在采集数据..."

# === 1. Git 状态 ===
cd "$WORKSPACE"
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
GIT_STATUS_OUTPUT=$(git status --porcelain 2>/dev/null)
GIT_LAST_COMMIT=$(git log -1 --format="%H|%ae|%ai|%s" 2>/dev/null || echo "N/A")
GIT_AHEAD=$(git rev-list --left-only --count HEAD...@{upstream} 2>/dev/null || echo "0")
GIT_BEHIND=$(git rev-list --right-only --count HEAD...@{upstream} 2>/dev/null || echo "0")
GIT_TRACKING=$(git rev-parse --abbrev-ref HEAD@{upstream} 2>/dev/null || echo "N/A")

# 解析 commit 信息
IFS='|' read -r COMMIT_HASH COMMIT_AUTHOR COMMIT_DATE COMMIT_MSG <<< "$GIT_LAST_COMMIT"

# === 2. 核心配置文件检查 ===
CONFIG_FILES="IDENTITY.md USER.md SOUL.md AGENTS.md MEMORY.md TOOLS.md HEARTBEAT.md"
CONFIG_STATUS_HTML=""
for file in $CONFIG_FILES; do
    if [ -f "$WORKSPACE/$file" ]; then
        CONFIG_STATUS_HTML="${CONFIG_STATUS_HTML}<li class=\"ok\">✅ $file</li>"
    else
        CONFIG_STATUS_HTML="${CONFIG_STATUS_HTML}<li class=\"fail\">❌ $file 不存在</li>"
    fi
done

# === 3. Memory 更新频率 ===
MEMORY_HTML=""
if [ -d "$WORKSPACE/memory" ]; then
    MEMORY_COUNT=$(find "$WORKSPACE/memory" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    MEMORY_HTML="${MEMORY_HTML}<li class=\"info\">共 ${MEMORY_COUNT} 个文件</li>"
    find "$WORKSPACE/memory" -type f -name "*.md" 2>/dev/null | while read -r file; do
        fname=$(basename "$file")
        mtime=$(stat -f "%Sm" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null)
        MEMORY_HTML="${MEMORY_HTML}<li class=\"ok\">📄 $fname — $mtime</li>"
    done
else
    MEMORY_HTML="<li class=\"warn\">📭 memory/ 目录为空或不存在</li>"
fi

# === 4. 系统资源 ===
CPU_LOAD=$(uptime | awk -F'load averages:' '{print $2}' | xargs)
MEMORY_USAGE=$(top -l 1 | grep "PhysMem" | awk '{print $2}' | head -1)
DISK_INFO=$(df -h "$WORKSPACE" 2>/dev/null | tail -1)
DISK_USAGE=$(echo "$DISK_INFO" | awk '{print $3 " / " $2 " (" $5 " used)"}')
UPTIME_INFO=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')

# === 5. HEARTBEAT 配置检查 ===
if [ -f "$WORKSPACE/HEARTBEAT.md" ]; then
    HB_SIZE=$(wc -c < "$WORKSPACE/HEARTBEAT.md")
    HB_LINES=$(wc -l < "$WORKSPACE/HEARTBEAT.md")
    HB_CONTENT=$(cat "$WORKSPACE/HEARTBEAT.md" | grep -v '^#' | grep -v '^$' | wc -c)
    if [ "$HB_CONTENT" -lt 50 ]; then
        HB_STATUS_HTML="<span class=\"warn\">⚠️ 配置为空或仅含注释</span>"
    else
        HB_STATUS_HTML="<span class=\"ok\">✅ 已配置</span>"
    fi
    HB_DETAIL="<p class=\"info\" style=\"margin-top:12px;font-size:12px;\">文件大小：${HB_SIZE} bytes | 行数：${HB_LINES}</p>"
else
    HB_STATUS_HTML="<span class=\"fail\">❌ HEARTBEAT.md 不存在</span>"
    HB_DETAIL=""
fi

# === 6. Git 状态显示 ===
if [ -z "$GIT_STATUS_OUTPUT" ]; then
    GIT_STATUS_HTML='<li class="clean">✅ 工作区干净</li>'
else
    GIT_STATUS_HTML='<li class="dirty">⚠️ 未提交的更改：</li>'
    while IFS= read -r line; do
        GIT_STATUS_HTML="${GIT_STATUS_HTML}<li class=\"dirty\" style=\"margin-left:16px;font-size:12px;\">$line</li>"
    done <<< "$GIT_STATUS_OUTPUT"
fi

# === 7. Commit 信息 ===
if [ "$GIT_LAST_COMMIT" != "N/A" ]; then
    COMMIT_HTML="<li class=\"ok\"><strong>${COMMIT_MSG}</strong></li>
    <li>📦 ${COMMIT_HASH:0:8}</li>
    <li>👤 ${COMMIT_AUTHOR}</li>
    <li>📅 ${COMMIT_DATE}</li>"
else
    COMMIT_HTML="<li class=\"fail\">无法获取 commit 信息</li>"
fi

# === 生成 HTML ===
cat > "$OUTPUT" << HTML
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Workspace 健康仪表盘</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f1419; color: #e6e6e6; min-height: 100vh; padding: 24px; }
        .container { max-width: 900px; margin: 0 auto; }
        h1 { color: #00d4ff; font-size: 28px; margin-bottom: 8px; }
        .subtitle { color: #7f8c8d; margin-bottom: 32px; }
        .timestamp { color: #7f8c8d; font-size: 12px; margin-top: 4px; }
        .grid { display: grid; grid: auto / repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; }
        .card { background: #1a2332; border-radius: 12px; padding: 20px; border: 1px solid #2d3a4d; }
        .card h2 { color: #00d4ff; font-size: 16px; margin-bottom: 16px; border-bottom: 1px solid #2d3a4d; padding-bottom: 10px; }
        .card ul { list-style: none; }
        .card li { padding: 6px 0; font-size: 14px; line-height: 1.5; }
        .ok { color: #2ecc71; }
        .fail { color: #e74c3c; }
        .warn { color: #f39c12; }
        .info { color: #3498db; }
        .stat-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #2d3a4d; }
        .stat-row:last-child { border-bottom: none; }
        .stat-label { color: #7f8c8d; }
        .stat-value { color: #e6e6e6; font-weight: 500; }
        .branch { display: inline-block; background: #2d3a4d; color: #00d4ff; padding: 4px 12px; border-radius: 20px; font-size: 14px; font-weight: bold; margin-bottom: 12px; }
        .sync-status { font-size: 12px; margin-left: 10px; }
        .ahead { color: #f39c12; }
        .behind { color: #e74c3c; }
        .clean { color: #2ecc71; }
        .dirty { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛠️ Workspace 健康仪表盘</h1>
        <p class="subtitle">~/.openclaw/workspace-metapivot</p>
        <p class="timestamp">报告生成时间：${TIMESTAMP}</p>

        <div class="grid">
            <!-- Git 状态 -->
            <div class="card">
                <h2>📊 Git 状态</h2>
                <span class="branch">🌿 ${GIT_BRANCH}</span>
                <span class="sync-status ahead">↑ ahead ${GIT_AHEAD}</span>
                <span class="sync-status behind">↓ behind ${GIT_BEHIND}</span>
                <ul>
                    ${GIT_STATUS_HTML}
                    <li style="margin-top:12px;font-weight:bold;color:#7f8c8d;">最近一次 commit：</li>
                    ${COMMIT_HTML}
                </ul>
            </div>

            <!-- 配置文件 -->
            <div class="card">
                <h2>📁 配置文件完整性</h2>
                <ul>
                    ${CONFIG_STATUS_HTML}
                </ul>
            </div>

            <!-- Memory 状态 -->
            <div class="card">
                <h2>🧠 Memory 更新频率</h2>
                <ul>
                    ${MEMORY_HTML}
                </ul>
            </div>

            <!-- 系统资源 -->
            <div class="card">
                <h2>💻 系统资源</h2>
                <ul>
                    <li class="stat-row"><span class="stat-label">CPU 负载</span><span class="stat-value info">${CPU_LOAD}</span></li>
                    <li class="stat-row"><span class="stat-label">内存使用</span><span class="stat-value info">${MEMORY_USAGE:-N/A}</span></li>
                    <li class="stat-row"><span class="stat-label">磁盘使用</span><span class="stat-value info">${DISK_USAGE:-N/A}</span></li>
                    <li class="stat-row"><span class="stat-label">运行时长</span><span class="stat-value info">${UPTIME_INFO:-N/A}</span></li>
                </ul>
            </div>

            <!-- HEARTBEAT 状态 -->
            <div class="card">
                <h2>💓 HEARTBEAT 状态</h2>
                <p>${HB_STATUS_HTML}</p>
                ${HB_DETAIL}
            </div>
        </div>
    </div>
</body>
</html>
HTML

echo "✅ 报告已生成：$OUTPUT"
