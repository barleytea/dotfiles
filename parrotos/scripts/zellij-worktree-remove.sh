#!/usr/bin/env bash
#
# zellij-worktree-remove.sh
# gwq + fzf で git worktree とブランチを削除するスクリプト
#
# Usage:
#   zellij-worktree-remove.sh              # worktreeのみ削除
#   zellij-worktree-remove.sh --branch     # worktreeとブランチを削除
#   zellij-worktree-remove.sh --force      # マージされてなくても強制削除

set -euo pipefail

# zellij のフローティングペインから実行される場合、標準入出力を端末に接続
exec < /dev/tty > /dev/tty 2>&1

# オプション解析
DELETE_BRANCH=false
FORCE_DELETE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --branch|-b)
            DELETE_BRANCH=true
            shift
            ;;
        --force|-f)
            FORCE_DELETE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--branch|-b] [--force|-f]"
            exit 1
            ;;
    esac
done

# gitリポジトリ内にいるか確認
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository"
    exit 1
fi

# gwq listをJSONで取得してworktree情報を得る
get_worktrees() {
    gwq list --json 2>/dev/null || echo "[]"
}

# 現在のブランチを取得
current_branch=$(git branch --show-current)

# fzfに渡すworktreeリストを生成
generate_worktree_list() {
    local worktrees
    worktrees=$(get_worktrees)

    if [ "$worktrees" = "[]" ] || [ -z "$worktrees" ]; then
        echo "No worktrees found"
        return 1
    fi

    echo "$worktrees" | jq -r '.[] | "\(.branch)\t\(.path)"' | while IFS=$'\t' read -r branch _; do
        if [ "$branch" = "$current_branch" ]; then
            echo "📍 $branch (current - cannot delete)"
        else
            echo "🌳 $branch"
        fi
    done
}

# fzfでworktreeを選択（複数選択可能）
selected=$(generate_worktree_list | grep -v "current - cannot delete" | grep "^🌳" | fzf --prompt="Select worktree to delete > " --height=40% --reverse --border --ansi --multi || true)

if [ -z "$selected" ]; then
    echo "No worktree selected"
    exit 0
fi

# 選択されたブランチを処理
echo "$selected" | while read -r line; do
    # マークを除去してブランチ名を取得
    branch="${line#🌳 }"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗑️  Removing: $branch"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # gwq removeコマンドを構築
    cmd="gwq remove"

    if [ "$DELETE_BRANCH" = true ]; then
        cmd="$cmd --delete-branch"
        if [ "$FORCE_DELETE" = true ]; then
            cmd="$cmd --force-delete-branch"
        fi
    fi

    if [ "$FORCE_DELETE" = true ]; then
        cmd="$cmd --force"
    fi

    cmd="$cmd \"$branch\""

    echo "Running: $cmd"
    eval "$cmd" && echo "✅ Successfully removed: $branch" || echo "❌ Failed to remove: $branch"
done

echo ""
echo "🎉 Done!"
echo ""
echo "Press Enter to close..."
read -r
