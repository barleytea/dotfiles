#!/usr/bin/env bash
#
# zellij-session-switcher.sh
# fzf で zellij セッションをサクサク切り替えるスクリプト

set -euo pipefail

# zellij のフローティングペインから実行される場合、標準入出力を端末に接続
exec < /dev/tty > /dev/tty 2>&1

# 現在のセッション名を取得
current_session="${ZELLIJ_SESSION_NAME:-}"

# セッション一覧を生成
generate_session_list() {
    # 新規セッション作成オプション
    echo "✨ [新規セッションを作成]"

    # 既存セッション一覧
    zellij list-sessions 2>/dev/null | while read -r line; do
        # セッション名を抽出（最初の単語）
        session_name=$(echo "$line" | awk '{print $1}')
        if [ -n "$session_name" ]; then
            if [ "$session_name" = "$current_session" ]; then
                echo "📍 $session_name (current)"
            else
                echo "🔌 $session_name"
            fi
        fi
    done
}

# fzfでセッションを選択
selected=$(generate_session_list | fzf --prompt="Select session > " --height=40% --reverse --border --ansi || true)

if [ -z "$selected" ]; then
    exit 0
fi

# 新規セッション作成が選択された場合
if [[ "$selected" == "✨ [新規セッションを作成]" ]]; then
    echo -n "新しいセッション名を入力: "
    read -r session_name
    if [ -z "$session_name" ]; then
        echo "セッション名が入力されませんでした"
        exit 1
    fi
    echo "🔄 Creating new session: $session_name"
    # ZELLIJ環境変数をunsetしてからattach（入れ子防止）
    unset ZELLIJ ZELLIJ_SESSION_NAME
    exec zellij attach --create "$session_name"
fi

# 現在のセッションが選択された場合は何もしない
if [[ "$selected" == *"(current)"* ]]; then
    echo "Already in this session!"
    sleep 1
    exit 0
fi

# マークを除去してセッション名を取得
session_name=$(echo "$selected" | sed 's/^📍 //' | sed 's/^🔌 //' | sed 's/ (current)$//')

echo "🔄 Switching to session: $session_name"

# ZELLIJ環境変数をunsetしてからattach（入れ子防止）
unset ZELLIJ ZELLIJ_SESSION_NAME
exec zellij attach "$session_name"
