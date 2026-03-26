#!/usr/bin/env bash
#
# cmux-workspace.sh
# fzf でブランチを選択し、git worktree を作成/再利用して cmux workspace を開く
#
# Usage:
#   cmux-workspace             # fzf でブランチを選択して cmux workspace を開く
#   cmux-workspace --claude    # Claude Code も起動する

set -euo pipefail

CMUX_BIN="/Applications/cmux.app/Contents/Resources/bin/cmux"
LAUNCH_CLAUDE=false

# オプション解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --claude|-c)
            LAUNCH_CLAUDE=true
            shift
            ;;
        --help|-h)
            echo "Usage: cmux-workspace [--claude|-c] [--help|-h]"
            echo ""
            echo "Options:"
            echo "  --claude, -c   Launch Claude Code in the new workspace"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: cmux-workspace [--claude|-c]"
            exit 1
            ;;
    esac
done

# cmux が利用可能か確認
if [[ ! -x "$CMUX_BIN" ]]; then
    echo "Error: cmux binary not found at $CMUX_BIN"
    echo "Ensure cmux is installed and Automation Mode is enabled."
    exit 1
fi

# git リポジトリ内にいるか確認
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository"
    exit 1
fi

# リポジトリルートとリポジトリ名を取得
repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")

# gwq で管理されている worktree のブランチ一覧を取得
get_worktree_branches() {
    gwq list --json 2>/dev/null | jq -r '.[].branch' 2>/dev/null || true
}

# ブランチに対応する worktree パスを取得
get_worktree_path() {
    local target_branch="$1"
    gwq list --json 2>/dev/null | jq -r --arg b "$target_branch" '.[] | select(.branch == $b) | .path' 2>/dev/null || true
}

# fzf に渡すブランチリストを生成
generate_branch_list() {
    echo "  [新規ブランチを作成]"

    local worktree_branches
    worktree_branches=$(get_worktree_branches)

    # 既存 worktree のブランチ
    if [[ -n "$worktree_branches" ]]; then
        echo "$worktree_branches" | while read -r b; do
            [[ -n "$b" ]] && echo "[worktree] $b"
        done
    fi

    # ローカルブランチ（worktree に含まれないもの）
    git branch --format='%(refname:short)' | while read -r b; do
        if ! echo "$worktree_branches" | grep -qx "$b" 2>/dev/null; then
            echo "$b"
        fi
    done

    # リモートブランチ（ローカルに存在しないもの）
    local local_branches
    local_branches=$(git branch --format='%(refname:short)')
    git branch -r --format='%(refname:short)' 2>/dev/null | grep -v 'HEAD' | sed 's|^origin/||' | while read -r b; do
        if ! echo "$local_branches" | grep -qx "$b" 2>/dev/null && \
           ! echo "$worktree_branches" | grep -qx "$b" 2>/dev/null; then
            echo "[remote] $b"
        fi
    done
}

# fzf でブランチを選択
selected=$(generate_branch_list | fzf \
    --prompt="Branch > " \
    --header="Repo: ${repo_name}" \
    --height=50% \
    --reverse \
    --border \
    --ansi || true)

if [[ -z "$selected" ]]; then
    exit 0
fi

# 新規ブランチ作成
if [[ "$selected" == "  [新規ブランチを作成]" ]]; then
    printf "新しいブランチ名を入力: "
    read -r branch
    if [[ -z "$branch" ]]; then
        echo "ブランチ名が入力されませんでした"
        exit 1
    fi
    echo "Creating new branch and worktree: $branch"
    gwq add -b "$branch" || {
        echo "Failed to create branch: $branch"
        exit 1
    }
    # デフォルトブランチをベースにリセット
    _wt_path=$(get_worktree_path "$branch")
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
    if [[ -n "$_wt_path" ]] && git rev-parse --verify "$default_branch" &>/dev/null; then
        git -C "$_wt_path" reset --hard "$default_branch" --quiet
        echo "Based on: $default_branch"
    fi
else
    # マークを除去してブランチ名を取得
    branch=$(echo "$selected" | sed 's/^\[worktree\] //' | sed 's/^\[remote\] //')

    # worktree が存在しない場合は作成
    if ! get_worktree_branches | grep -qx "$branch" 2>/dev/null; then
        echo "Creating worktree for branch: $branch"
        gwq add "$branch" 2>/dev/null || {
            echo "Remote branch not found locally. Creating new branch..."
            gwq add -b "$branch" || exit 1
        }
    fi
fi

# worktree パスを取得
worktree_path=$(get_worktree_path "$branch")

if [[ -z "$worktree_path" ]]; then
    echo "Error: Could not find worktree path for branch: $branch"
    exit 1
fi

echo "Opening cmux workspace: $branch"
echo "Path: $worktree_path"

# cmux でワークスペースを開く
"$CMUX_BIN" "$worktree_path"

# ワークスペース名をブランチ名に変更
sleep 0.5
workspace_title="${repo_name}/${branch//\//-}"
"$CMUX_BIN" rename-workspace "$workspace_title" 2>/dev/null || true

# Claude Code を起動（--claude オプション指定時）
if [[ "$LAUNCH_CLAUDE" == true ]]; then
    sleep 0.3
    "$CMUX_BIN" send "claude" 2>/dev/null || true
    "$CMUX_BIN" send-key Enter 2>/dev/null || true
fi

echo "Done: $workspace_title"
