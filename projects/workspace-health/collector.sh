#!/bin/bash
# Workspace Health Collector - 后台持续采集
# 每分钟采集一次，写入 data/latest.json 和 data/history/
# Usage: ./collector.sh [interval_seconds]

INTERVAL=${1:-60}
WORKSPACE="$HOME/.openclaw/workspace-metapivot"
DATA_DIR="$WORKSPACE/projects/workspace-health/data"
mkdir -p "$DATA_DIR/history"

echo "🫀 Workspace Health Collector 启动 (间隔: ${INTERVAL}s)"
echo "按 Ctrl+C 停止"

collect() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    TIMESTAMP_UNIX=$(date '+%s')
    
    # === Git ===
    cd "$WORKSPACE"
    GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
    GIT_STATUS_OUTPUT=$(git status --porcelain 2>/dev/null)
    GIT_CLEAN=0
    if [ -z "$GIT_STATUS_OUTPUT" ]; then
        GIT_CLEAN=1
    fi
    GIT_LAST_COMMIT=$(git log -1 --format="%H|%ae|%ai|%s" 2>/dev/null || echo "N/A")
    IFS='|' read -r COMMIT_HASH COMMIT_AUTHOR COMMIT_DATE COMMIT_MSG <<< "$GIT_LAST_COMMIT"
    
    # === Remote sync ===
    HAS_REMOTE=0
    IS_SYNCED=0
    if git remote -v 2>/dev/null | grep -q 'github.com'; then
        HAS_REMOTE=1
        git fetch origin 2>/dev/null
        LOCAL=$(git rev-parse @ 2>/dev/null)
        REMOTE=$(git rev-parse @{u} 2>/dev/null)
        if [ "$LOCAL" = "$REMOTE" ] && [ -n "$REMOTE" ]; then
            IS_SYNCED=1
        fi
    fi
    
    # === Config files ===
    CONFIG_FILES="IDENTITY.md USER.md SOUL.md AGENTS.md MEMORY.md TOOLS.md HEARTBEAT.md"
    CONFIG_COMPLETE=1
    CONFIG_LIST=""
    for file in $CONFIG_FILES; do
        if [ -f "$WORKSPACE/$file" ]; then
            CONFIG_LIST="${CONFIG_LIST}\"${file}\","
        else
            CONFIG_COMPLETE=0
        fi
    done
    CONFIG_LIST=${CONFIG_LIST%,}
    
    # === Memory ===
    MEMORY_COUNT=$(find "$WORKSPACE/memory" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    
    # === System - CPU ===
    CPU_LOAD=$(uptime | awk -F'load averages:' '{print $2}' | xargs | awk '{print $1}' | sed 's/,//')
    
    # === System - Disk ===
    DISK_PCT=$(df "$WORKSPACE" 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
    
    # === System - Memory (macOS compatible) ===
    FREE=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    ACTIVE=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.')
    INACTIVE=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
    SPEC=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | tr -d '.')
    WIRED=$(vm_stat | grep "Pages wired" | awk '{print $4}' | tr -d '.')
    COMPRESSED=$(vm_stat | grep "Pages stored in compressor" | awk '{print $3}' | tr -d '.')
    
    # Fallback if any is empty
    FREE=${FREE:-0}; ACTIVE=${ACTIVE:-0}; INACTIVE=${INACTIVE:-0}
    SPEC=${SPEC:-0}; WIRED=${WIRED:-0}; COMPRESSED=${COMPRESSED:-0}
    
    USED_MEM=$((ACTIVE + WIRED + COMPRESSED))
    TOTAL_MEM=$((FREE + ACTIVE + INACTIVE + SPEC + WIRED + COMPRESSED))
    if [ "$TOTAL_MEM" -gt 0 ] 2>/dev/null; then
        MEM_PCT=$(printf "%.0f" "$(echo "scale=4; $USED_MEM * 100 / $TOTAL_MEM" | bc 2>/dev/null || echo "0")")
    else
        MEM_PCT=0
    fi
    
    # === HEARTBEAT ===
    HB_EFFECTIVE=0
    if [ -f "$WORKSPACE/HEARTBEAT.md" ]; then
        HB_CONTENT=$(cat "$WORKSPACE/HEARTBEAT.md" | grep -v '^#' | grep -v '^$' | wc -c)
        if [ "$HB_CONTENT" -gt 50 ]; then
            HB_EFFECTIVE=1
        fi
    fi
    
    # === Health Score ===
    SCORE=0
    [ "$GIT_BRANCH" != "N/A" ] && [ -n "$GIT_BRANCH" ] && SCORE=$((SCORE+10))
    [ "$GIT_CLEAN" -eq 1 ] && SCORE=$((SCORE+20))
    [ "$HB_EFFECTIVE" -eq 1 ] && SCORE=$((SCORE+10))
    [ "${MEM_PCT:-0}" -lt 80 ] && SCORE=$((SCORE+15))
    [ "${DISK_PCT:-0}" -lt 85 ] && SCORE=$((SCORE+15))
    [ "$CONFIG_COMPLETE" -eq 1 ] && SCORE=$((SCORE+20))
    [ "$HAS_REMOTE" -eq 1 ] && [ "$IS_SYNCED" -eq 1 ] && SCORE=$((SCORE+10))
    
    # === Disk warning ===
    DISK_WARNING=0
    [ "${DISK_PCT:-0}" -ge 85 ] && DISK_WARNING=1
    [ "${DISK_PCT:-0}" -ge 95 ] && DISK_WARNING=2
    
    # Escape message for JSON
    COMMIT_MSG_ESC=$(echo "$COMMIT_MSG" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r//g; s/\n/\\n/g' 2>/dev/null || echo "")
    
    # === Build JSON ===
    cat > "$DATA_DIR/latest.json" << JSON
{
    "timestamp": "$TIMESTAMP",
    "timestamp_unix": $TIMESTAMP_UNIX,
    "git": {
        "branch": "$GIT_BRANCH",
        "clean": $GIT_CLEAN,
        "has_remote": $HAS_REMOTE,
        "synced": $IS_SYNCED,
        "last_commit": {
            "hash": "${COMMIT_HASH:-N/A}",
            "author": "${COMMIT_AUTHOR:-N/A}",
            "date": "${COMMIT_DATE:-N/A}",
            "message": "$COMMIT_MSG_ESC"
        }
    },
    "config": {
        "complete": $CONFIG_COMPLETE,
        "files": [$CONFIG_LIST]
    },
    "memory": {
        "count": ${MEMORY_COUNT:-0}
    },
    "system": {
        "cpu_load": "$CPU_LOAD",
        "memory_pct": ${MEM_PCT:-0},
        "disk_pct": ${DISK_PCT:-0},
        "disk_warning": $DISK_WARNING
    },
    "heartbeat": {
        "effective": $HB_EFFECTIVE
    },
    "score": $SCORE
}
JSON
    
    # Save to history
    HIST_FILE="$DATA_DIR/history/${TIMESTAMP_UNIX}.json"
    cp "$DATA_DIR/latest.json" "$HIST_FILE"
    
    # Trim history to 100 entries
    ls -t "$DATA_DIR/history/"*.json 2>/dev/null | tail -n +101 | xargs rm -f 2>/dev/null || true
    
    echo "[$(date '+%H:%M:%S')] 采集完成 | 健康分: $SCORE | Git: $GIT_BRANCH | 磁盘: ${DISK_PCT:-0}% | 内存: ${MEM_PCT:-0}%"
}

# Initial run
collect

# Loop
while true; do
    sleep "$INTERVAL"
    collect
done
