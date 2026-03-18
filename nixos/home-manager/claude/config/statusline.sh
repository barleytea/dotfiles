#!/usr/bin/env bash

# Claude Code カスタムstatuslineスクリプト
# 要件:
# 1. model.display_name を表示
# 2. 現在の作業ディレクトリ名（basename）を表示
# 3. Gitブランチ名を表示
# 4. セッション費用 / 当日費用
# 5. 今月の累計費用
# 6. 1時間あたりの消費ペース（burn rate）
# 7. コンテキスト使用率（%）

# ANSIカラー定義
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
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
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
DIR_NAME=$(basename "$DIR")
CONTEXT_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%.0f", $1}')
CONTEXT_USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
CONTEXT_MAX=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
# K単位に変換。0の場合はトークン表示を省略するためフラグを立てる
if [ "$CONTEXT_MAX" != "0" ] && [ -n "$CONTEXT_MAX" ]; then
    CONTEXT_USED_K=$(awk "BEGIN {printf \"%.0fK\", $CONTEXT_USED / 1000}" 2>/dev/null || echo "?K")
    CONTEXT_MAX_K=$(awk "BEGIN {printf \"%.0fK\", $CONTEXT_MAX / 1000}" 2>/dev/null || echo "?K")
    CONTEXT_TOKEN_DISPLAY=" (${CONTEXT_USED_K}/${CONTEXT_MAX_K})"
else
    CONTEXT_TOKEN_DISPLAY=""
fi

# Gitブランチ名を取得（キャッシュで高速化）
# ディレクトリパスをハッシュ化してキャッシュファイル名を作成
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

# 今月の累計費用を取得（キャッシュで高速化、60秒間隔）
MONTHLY_CACHE="/tmp/statusline-monthly-cache"
MONTHLY_CACHE_MAX_AGE=60

if [ ! -f "$MONTHLY_CACHE" ] || [ $(( $(date +%s) - $(get_mtime "$MONTHLY_CACHE") )) -gt $MONTHLY_CACHE_MAX_AGE ]; then
    MONTHLY_COST=$(run_ccusage monthly --json --offline 2>/dev/null | jq -r --arg month "$(date +%Y-%m)" '([.monthly[]? | select(.month == $month) | .totalCost] | first) // 0' 2>/dev/null || echo "0")
    echo "$MONTHLY_COST" > "$MONTHLY_CACHE"
else
    MONTHLY_COST=$(cat "$MONTHLY_CACHE" 2>/dev/null || echo "0")
fi

if ! [[ "$MONTHLY_COST" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    MONTHLY_COST="0"
fi

# ccusage statuslineを呼び出して費用情報を取得
CCUSAGE_OUTPUT=$(echo "$input" | run_ccusage statusline --offline 2>/dev/null || echo "")

# セッション費用とburn rateをClaude Code APIから取得（フォールバック）
SESSION_COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# コンテキスト使用率に応じた色とプログレスバーを生成
make_context_bar() {
    local pct="$1"
    local filled=$(awk "BEGIN {printf \"%d\", $pct / 10}" 2>/dev/null || echo 0)
    [ "$filled" -gt 10 ] && filled=10
    local empty=$(( 10 - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done
    if [ "$pct" -ge 80 ]; then
        echo -e "${RED}[${bar}]${RESET}"
    elif [ "$pct" -ge 50 ]; then
        echo -e "${YELLOW}[${bar}]${RESET}"
    else
        echo -e "${GREEN}[${bar}]${RESET}"
    fi
}

# 費用に応じた色を返す（セッション費用用）
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

# 出力フォーマット
# 1行目: モデル名 | ディレクトリ名 | Gitブランチ（カラー付き）
if [ -n "$BRANCH" ]; then
    LINE1="🤖 ${CYAN}${BOLD}${MODEL}${RESET} │ 📁 ${BOLD}${DIR_NAME}${RESET} │ 🌿 ${GREEN}${BRANCH}${RESET}"
else
    LINE1="🤖 ${CYAN}${BOLD}${MODEL}${RESET} │ 📁 ${BOLD}${DIR_NAME}${RESET}"
fi

# 2行目: ccusageの出力（セッション費用/当日費用/burn rate等が含まれる）
# または、ccusageが失敗した場合はフォールバック（カラー+プログレスバー付き）
if [ -n "$CCUSAGE_OUTPUT" ]; then
    # ccusageの出力からモデル名部分とburn rateを削除
    LINE2=$(echo "$CCUSAGE_OUTPUT" | sed 's/^🤖 [^|]* | //' | sed 's/ | 🔥 [^|]*//')
    # プログレスバーとトークン数を末尾に追加（%はccusageのものをそのまま使用）
    CTX_BAR=$(make_context_bar "$CONTEXT_PCT")
    LINE2="${LINE2} ${CTX_BAR}${CONTEXT_TOKEN_DISPLAY}"
else
    # フォールバック: カラー+プログレスバー付きで表示
    SESSION_COLOR=$(cost_color "$SESSION_COST" "0.50" "0.10")
    CTX_BAR=$(make_context_bar "$CONTEXT_PCT")
    LINE2="💰 ${SESSION_COLOR}\$$(printf '%.4f' "$SESSION_COST")${RESET} session │ 🧠 ${CTX_BAR} ${CONTEXT_PCT}%${CONTEXT_TOKEN_DISPLAY}"
fi

# 3行目: 今月の累計費用（閾値ベースのカラー付き）
MONTHLY_FMT=$(printf '%.2f' "$MONTHLY_COST")
MONTHLY_COLOR=$(cost_color "$MONTHLY_COST" "50.00" "10.00")
LINE3="📊 今月累計: ${MONTHLY_COLOR}\$${MONTHLY_FMT}${RESET}"

# 最終出力（複数行）
echo -e "$LINE1"
echo -e "$LINE2"
echo -e "$LINE3"
