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

# 入力JSONを読み込み
input=$(cat)

# ccusage を安全に実行（未インストール時は失敗を返す）
run_ccusage() {
    if command -v ccusage > /dev/null 2>&1; then
        ccusage "$@"
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
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Burn rate計算（1時間あたりの消費ペース）
if [ "$DURATION_MS" != "0" ] && [ -n "$DURATION_MS" ]; then
    # awkを使用してbc非依存で計算（より移植性が高い）
    BURN_RATE=$(awk "BEGIN {printf \"%.2f\", $SESSION_COST / ($DURATION_MS / 3600000)}" 2>/dev/null || echo "0.00")
else
    BURN_RATE="0.00"
fi

# 出力フォーマット
# 1行目: モデル名 | ディレクトリ名 | Gitブランチ
if [ -n "$BRANCH" ]; then
    LINE1="🤖 ${MODEL} | 📁 ${DIR_NAME} | 🌿 ${BRANCH}"
else
    LINE1="🤖 ${MODEL} | 📁 ${DIR_NAME}"
fi

# 2行目: ccusageの出力（セッション費用/当日費用/burn rate等が含まれる）
# または、ccusageが失敗した場合はフォールバック
if [ -n "$CCUSAGE_OUTPUT" ]; then
    # ccusageの出力からモデル名部分を削除（重複を避けるため）
    LINE2=$(echo "$CCUSAGE_OUTPUT" | sed 's/^🤖 [^|]* | //')
else
    # フォールバック: 基本情報のみ表示
    LINE2="💰 \$$(printf '%.4f' "$SESSION_COST") session | 🔥 \$${BURN_RATE}/hr | 🧠 ${CONTEXT_PCT}%"
fi

# 3行目: 今月の累計費用
MONTHLY_FMT=$(printf '%.2f' "$MONTHLY_COST")
LINE3="📊 今月累計: \$${MONTHLY_FMT}"

# 最終出力（複数行）
echo "$LINE1"
echo "$LINE2"
echo "$LINE3"
