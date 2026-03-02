#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Claude Code Status Line — combined edition                 ║
# ║  Visual style + real OAuth usage API limits                 ║
# ╚══════════════════════════════════════════════════════════════╝

USAGE_CACHE="/tmp/claude-statusline-usage.json"
USAGE_CACHE_AGE=60  # seconds between API calls

input=$(cat)

# ── Extract Claude Code data ──────────────────────────────────
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
MODEL_ID=$(echo "$input" | jq -r '.model.id // ""')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
DIR_NAME=$(basename "$DIR")
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CTX_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# ── Colors & styles ───────────────────────────────────────────
RST=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
RED=$'\033[91m'; GRN=$'\033[32m'; YLW=$'\033[33m'
BLU=$'\033[34m'; MAG=$'\033[35m'; CYN=$'\033[36m'
WHT=$'\033[37m'; BGRY=$'\033[90m'

# ── Color picker: green < 50%, yellow 50-80%, red > 80% ──────
pick_color() {
    local pct=$1
    if   [ "$pct" -gt 80 ]; then echo "$RED"
    elif [ "$pct" -ge 50 ]; then echo "$YLW"
    else echo "$GRN"; fi
}

# ── Progress bar ━━━╌╌╌ ──────────────────────────────────────
make_bar() {
    local pct=$1 w=${2:-10}
    local clr=$(pick_color "$pct")
    [ "$pct" -gt 100 ] && pct=100
    [ "$pct" -lt 0 ] && pct=0
    local filled=$((pct * w / 100))
    [ "$pct" -gt 0 ] && [ "$filled" -eq 0 ] && filled=1
    local empty=$((w - filled))
    local bar=""
    [ "$filled" -gt 0 ] && bar=$(printf "%${filled}s" | tr ' ' '━')
    [ "$empty"  -gt 0 ] && bar="${bar}$(printf "%${empty}s" | tr ' ' '╌')"
    printf "%s%s%s" "$clr" "$bar" "$RST"
}

# ── Fetch usage from OAuth API (cached) ──────────────────────
fetch_usage() {
    if [ -f "$USAGE_CACHE" ]; then
        local age=$(( $(date +%s) - $(stat -f %m "$USAGE_CACHE" 2>/dev/null || echo 0) ))
        if [ "$age" -lt "$USAGE_CACHE_AGE" ]; then
            cat "$USAGE_CACHE"
            return
        fi
    fi
    local creds token resp
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [ -z "$token" ]; then
        [ -f "$USAGE_CACHE" ] && cat "$USAGE_CACHE"
        return
    fi
    resp=$(curl -s --max-time 5 "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Content-Type: application/json" 2>/dev/null)
    if echo "$resp" | jq -e '.five_hour' >/dev/null 2>&1; then
        echo "$resp" > "$USAGE_CACHE"
        echo "$resp"
    else
        [ -f "$USAGE_CACHE" ] && cat "$USAGE_CACHE"
    fi
}

USAGE=$(fetch_usage)

# ── Parse usage data ──────────────────────────────────────────
FIVE_HR_PCT=0; FIVE_HR_RESET=""; SEVEN_DAY_PCT=0; SEVEN_DAY_RESET=""
if [ -n "$USAGE" ]; then
    FIVE_HR_PCT=$(echo "$USAGE" | jq -r '.five_hour.utilization // 0' | cut -d. -f1)
    FIVE_HR_RESET=$(echo "$USAGE" | jq -r '.five_hour.resets_at // empty')
    SEVEN_DAY_PCT=$(echo "$USAGE" | jq -r '.seven_day.utilization // 0' | cut -d. -f1)
    SEVEN_DAY_RESET=$(echo "$USAGE" | jq -r '.seven_day.resets_at // empty')
fi

# ── Format reset times ───────────────────────────────────────
fmt_5h=""
if [ -n "$FIVE_HR_RESET" ] && [ "$FIVE_HR_RESET" != "null" ]; then
    ep=$(date -juf "%Y-%m-%dT%H:%M:%S" "${FIVE_HR_RESET%%.*}" "+%s" 2>/dev/null || echo 0)
    [ "$ep" -gt 0 ] && fmt_5h=$(date -jf "%s" "$ep" "+%-l%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')
fi
fmt_7d=""
if [ -n "$SEVEN_DAY_RESET" ] && [ "$SEVEN_DAY_RESET" != "null" ]; then
    ep=$(date -juf "%Y-%m-%dT%H:%M:%S" "${SEVEN_DAY_RESET%%.*}" "+%s" 2>/dev/null || echo 0)
    [ "$ep" -gt 0 ] && fmt_7d=$(date -jf "%s" "$ep" "+%a %-l%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')
fi

# ── Git info ──────────────────────────────────────────────────
GIT_STR=""
if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$DIR" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)
    DIRTY=""
    if ! git -C "$DIR" -c core.useBuiltinFSMonitor=false diff-index --quiet HEAD -- 2>/dev/null; then
        DIRTY="${YLW}*${RST}"
    fi
    GIT_STR=" ${BGRY}│${RST} ${MAG}⎇${RST} ${CYN}${BRANCH}${RST}${DIRTY}"
fi

# ── Lines changed ─────────────────────────────────────────────
LINES_STR=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
    LINES_STR=" ${BGRY}│${RST} ${GRN}+${LINES_ADD}${RST} ${RED}-${LINES_DEL}${RST}"
fi

# ── Model icon ────────────────────────────────────────────────
case "$MODEL" in
    *Opus*)   M_ICON="◆"; M_CLR="$MAG" ;;
    *Sonnet*) M_ICON="◇"; M_CLR="$BLU" ;;
    *Haiku*)  M_ICON="○"; M_CLR="$CYN" ;;
    *)        M_ICON="●"; M_CLR="$WHT" ;;
esac

# ── Session duration ──────────────────────────────────────────
SECS=$((DURATION_MS / 1000))
if [ "$SECS" -ge 3600 ]; then
    H=$((SECS / 3600)); M=$(((SECS % 3600) / 60))
    TIME_STR="${H}h${M}m"
elif [ "$SECS" -ge 60 ]; then
    M=$((SECS / 60)); S=$((SECS % 60))
    TIME_STR="${M}m${S}s"
else
    TIME_STR="${SECS}s"
fi

# ── Cost formatting ───────────────────────────────────────────
COST_FMT=$(printf '%.2f' "$COST")

# ── Labels with reset times ──────────────────────────────────
FIVE_LBL="5h"
[ -n "$fmt_5h" ] && FIVE_LBL="5h ${DIM}${fmt_5h}${RST}"
WEEK_LBL="wk"
[ -n "$fmt_7d" ] && WEEK_LBL="wk ${DIM}${fmt_7d}${RST}"

# ══════════════════════════════════════════════════════════════
#  OUTPUT
# ══════════════════════════════════════════════════════════════
BAR_W=10
SEP=" ${BGRY}│${RST} "

# Line 1: model + dir + git + cost + time + lines
echo -e "${M_CLR}${M_ICON} ${MODEL}${RST}${SEP}${GRN}${BOLD}${DIR_NAME}${RST}${GIT_STR}${SEP}${YLW}\$${COST_FMT}${RST}${SEP}${BLU}⏱ ${TIME_STR}${RST}${LINES_STR}"

# Line 2: ctx + 5h + wk progress bars
echo -e "${DIM}ctx${RST} $(make_bar "$CTX_USED" $BAR_W) ${BOLD}${CTX_USED}%${RST}${SEP}${FIVE_LBL} $(make_bar "$FIVE_HR_PCT" $BAR_W) ${BOLD}${FIVE_HR_PCT}%${RST}${SEP}${WEEK_LBL} $(make_bar "$SEVEN_DAY_PCT" $BAR_W) ${BOLD}${SEVEN_DAY_PCT}%${RST}"
