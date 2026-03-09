#!/usr/bin/env bash
# claude-add-dir.sh
# カレントディレクトリ + fzf で選んだプロジェクトを --add-dir 付きで claude 起動

set -euo pipefail

# fzf で候補リスト生成（ghq + worktrees）
generate_project_list() {
    # ghq リポジトリ一覧
    ghq list --full-path 2>/dev/null || true
    # ~/worktrees 配下の git リポジトリ
    local worktree_dir="${HOME}/worktrees"
    if [[ -d "$worktree_dir" ]]; then
        find "$worktree_dir" -name ".git" -maxdepth 3 -exec dirname {} \; 2>/dev/null || true
    fi
}

# カレントディレクトリを除外してソート・重複除去
current_dir=$(pwd -P)
candidates=$(generate_project_list | grep -v "^${current_dir}$" | sort -u)

# fzf で複数選択（ESC/空選択なら --add-dir なしで claude 起動）
selected=$(echo "$candidates" | fzf --multi \
    --prompt="Add dirs (Tab=select, Enter=confirm) > " \
    --header="Main: ${current_dir}" \
    --preview "bat --color=always --style=header,grid --line-range :80 {}/README.* 2>/dev/null || ls -la {}" \
    --height=60% --reverse --border || true)

# --add-dir 引数を構築
add_dir_args=()
if [[ -n "$selected" ]]; then
    while IFS= read -r dir; do
        [[ -n "$dir" ]] && add_dir_args+=("--add-dir" "$dir")
    done <<< "$selected"
fi

# claude 起動
exec claude "${add_dir_args[@]}" "$@"
