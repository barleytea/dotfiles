#!/usr/bin/env bash

# Claude Code カスタムstatuslineスクリプト
# 要件:
# 1. model.display_name を表示
# 2. 現在の作業ディレクトリ名（basename）を表示
# 3. Gitブランチ名を表示
# 4. コンテキスト使用率（ctx bar）
# 5. 5時間/7日間ウィンドウ使用率（rate_limits bar）
# 6. ブロック残り時間
# 7. 今月の累計費用

# ANSIカラー定義
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# 入力JSONを読み込み
input=$(cat)

# ccusage を安全に実行（未インストール時は失敗を返す）
run_ccusage() {
    if command -v ccusage > /dev/null 2>&1; then
        ccusage "$@"
    elif command -v npx > /dev/null 2>&1; then
        npx --yes ccusage "$@"
    else
        return 127
    fi
}

# ファイル更新時刻（epoch秒）をOS差分を吸収して取得
get_mtime() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo 0
        return
    fi

    if stat -c %Y "$file" > /dev/null 2>&1; then
        stat -c %Y "$file"
    elif stat -f %m "$file" > /dev/null 2>&1; then
        stat -f %m "$file"
    else
        echo 0
    fi
}

# 基本情報を取得
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
# "Claude Sonnet 4.6" → "Sonnet4.6" のように短縮
MODEL_SHORT=$(echo "$MODEL" | sed 's/^Claude //' | tr -d ' ')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
DIR_NAME=$(basename "$DIR")
CONTEXT_USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
CONTEXT_MAX=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
# total_input_tokens / context_window_size から計算
if [ "$CONTEXT_MAX" != "0" ] && [ -n "$CONTEXT_MAX" ] && [ "$CONTEXT_MAX" -gt 0 ] 2>/dev/null; then
    CONTEXT_PCT=$(awk "BEGIN {printf \"%.0f\", $CONTEXT_USED / $CONTEXT_MAX * 100}" 2>/dev/null || echo 0)
else
    CONTEXT_PCT=0
fi

# rate_limits (v2.1.80+)
WINDOW_5H_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' \
    | awk '{printf "%.0f", $1}' 2>/dev/null || echo "")

WINDOW_7D_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' \
    | awk '{printf "%.0f", $1}' 2>/dev/null || echo "")

# Gitブランチ名を取得（キャッシュで高速化）
DIR_HASH=$(echo -n "$DIR" | md5sum 2>/dev/null | cut -d' ' -f1 || echo -n "$DIR" | md5 2>/dev/null || echo "default")
CACHE_FILE="/tmp/statusline-git-cache-${DIR_HASH}"
CACHE_MAX_AGE=5

if [ ! -f "$CACHE_FILE" ] || [ $(( $(date +%s) - $(get_mtime "$CACHE_FILE") )) -gt $CACHE_MAX_AGE ]; then
    if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null || echo "detached")
    else
        BRANCH=""
    fi
    echo "$BRANCH" > "$CACHE_FILE"
else
    BRANCH=$(cat "$CACHE_FILE" 2>/dev/null || echo "")
fi

# 今月の累計費用を取得（キャッシュで高速化、300秒間隔）
# --offline を外してネットワーク経由で最新モデル価格を取得
MONTHLY_CACHE="/tmp/statusline-monthly-cache"
MONTHLY_CACHE_MAX_AGE=300

if [ ! -f "$MONTHLY_CACHE" ] || [ $(( $(date +%s) - $(get_mtime "$MONTHLY_CACHE") )) -gt $MONTHLY_CACHE_MAX_AGE ]; then
    MONTHLY_COST=$(run_ccusage monthly --json 2>/dev/null | jq -r --arg month "$(date +%Y-%m)" '([.monthly[]? | select(.month == $month) | .totalCost] | first) // 0' 2>/dev/null || echo "0")
    echo "$MONTHLY_COST" > "$MONTHLY_CACHE"
else
    MONTHLY_COST=$(cat "$MONTHLY_CACHE" 2>/dev/null || echo "0")
fi

if ! [[ "$MONTHLY_COST" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    MONTHLY_COST="0"
fi

# ブロック残り時間を取得（キャッシュ: 30秒）
BLOCK_CACHE="/tmp/statusline-block-cache"
BLOCK_CACHE_MAX_AGE=30

if [ ! -f "$BLOCK_CACHE" ] || [ $(( $(date +%s) - $(get_mtime "$BLOCK_CACHE") )) -gt $BLOCK_CACHE_MAX_AGE ]; then
    BLOCK_REMAINING=$(run_ccusage blocks --json --active --offline 2>/dev/null \
        | jq -r '.blocks[]? | select(.isActive == true) | .projection.remainingMinutes // ""' 2>/dev/null || echo "")
    echo "$BLOCK_REMAINING" > "$BLOCK_CACHE"
else
    BLOCK_REMAINING=$(cat "$BLOCK_CACHE" 2>/dev/null || echo "")
fi

# 使用率をリングアイコン（5段階）で表現（パターン3: Ring Meter）
make_ring() {
    local pct="$1"
    local idx=$(awk "BEGIN {idx = int($pct / 25); if (idx > 4) idx = 4; print idx}" 2>/dev/null || echo 0)
    local rings=('○' '◔' '◑' '◕' '●')
    local ring="${rings[$idx]}"
    if [ "$pct" -ge 80 ]; then
        echo -e "${RED}${ring}${RESET}"
    elif [ "$pct" -ge 50 ]; then
        echo -e "${YELLOW}${ring}${RESET}"
    else
        echo -e "${GREEN}${ring}${RESET}"
    fi
}

# 費用に応じた色を返す
cost_color() {
    local cost="$1"
    local high="${2:-0.50}"
    local mid="${3:-0.10}"
    if awk "BEGIN {exit !($cost >= $high)}"; then
        echo -e "${RED}"
    elif awk "BEGIN {exit !($cost >= $mid)}"; then
        echo -e "${YELLOW}"
    else
        echo -e "${GREEN}"
    fi
}

# ディレクトリ＆ブランチ
if [ -n "$BRANCH" ]; then
    LOCATION_PART="${BOLD}${DIR_NAME}${RESET} ${GREEN}${BRANCH}${RESET}"
else
    LOCATION_PART="${BOLD}${DIR_NAME}${RESET}"
fi

# コンテキストリング
CTX_RING=$(make_ring "$CONTEXT_PCT")
CTX_PART="ctx ${CTX_RING} ${CONTEXT_PCT}%"

# 5hウィンドウリング（値が存在する場合のみ）
WIN_5H_PART=""
if [[ "$WINDOW_5H_PCT" =~ ^[0-9]+$ ]]; then
    WIN_5H_RING=$(make_ring "$WINDOW_5H_PCT")
    WIN_5H_PART="5h ${WIN_5H_RING} ${WINDOW_5H_PCT}%"
fi

# 7dウィンドウリング（値が存在する場合のみ）
WIN_7D_PART=""
if [[ "$WINDOW_7D_PCT" =~ ^[0-9]+$ ]]; then
    WIN_7D_RING=$(make_ring "$WINDOW_7D_PCT")
    WIN_7D_PART="7d ${WIN_7D_RING} ${WINDOW_7D_PCT}%"
fi

# ブロック残り時間パート（⏳直後スペースなし）
BLOCK_PART=""
if [[ "$BLOCK_REMAINING" =~ ^[0-9]+$ ]]; then
    if [ "$BLOCK_REMAINING" -ge 60 ]; then
        BLOCK_H=$(( BLOCK_REMAINING / 60 ))
        BLOCK_M=$(( BLOCK_REMAINING % 60 ))
        BLOCK_FMT="${BLOCK_H}h${BLOCK_M}m"
    else
        BLOCK_FMT="${BLOCK_REMAINING}m"
    fi
    if [ "$BLOCK_REMAINING" -le 30 ]; then
        TIME_COLOR="${RED}"
    elif [ "$BLOCK_REMAINING" -le 60 ]; then
        TIME_COLOR="${YELLOW}"
    else
        TIME_COLOR="${GREEN}"
    fi
    BLOCK_PART="${TIME_COLOR}${BLOCK_FMT}${RESET}"
fi

# 今月累計（/mo省略、$マークで月額と明示）
MONTHLY_FMT=$(printf '%.2f' "$MONTHLY_COST")
MONTHLY_COLOR=$(cost_color "$MONTHLY_COST" "50.00" "10.00")
MONTHLY_PART="${MONTHLY_COLOR}\$${MONTHLY_FMT}/mo${RESET}"

# 1行に組み立て（区切りを · に変更してコンパクト化）
SEP=" | "
LINE="${CYAN}${MODEL_SHORT}${RESET}${SEP}${LOCATION_PART}${SEP}${CTX_PART}"
[ -n "$WIN_5H_PART" ] && LINE="${LINE}${SEP}${WIN_5H_PART}"
[ -n "$WIN_7D_PART" ] && LINE="${LINE}${SEP}${WIN_7D_PART}"
[ -n "$BLOCK_PART" ]  && LINE="${LINE}${SEP}${BLOCK_PART}"
LINE="${LINE}${SEP}${MONTHLY_PART}"

# 最終出力（1行）
echo -e "$LINE"
