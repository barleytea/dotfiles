#!/usr/bin/env bash
#
# cmux-workspace.sh
# fzf でブランチを選択し、git worktree を作成/再利用して cmux workspace を開く
#
# Usage:
#   cmux-workspace             # fzf でブランチを選択して cmux workspace を開く
#   cmux-workspace --claude    # Claude Code も起動する

set -euo pipefail

# ── Dracula color palette ─────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
FG_GREEN='\033[38;2;80;250;123m'    # #50FA7B  worktree
FG_CYAN='\033[38;2;139;233;253m'    # #8BE9FD  remote
FG_PINK='\033[38;2;255;121;198m'    # #FF79C6  new / prompt
FG_PURPLE='\033[38;2;189;147;249m'  # #BD93F9  accent
FG_YELLOW='\033[38;2;241;250;140m'  # #F1FA8C  info
FG_ORANGE='\033[38;2;255;184;108m'  # #FFB86C  warning
FG_FG='\033[38;2;248;248;242m'      # #F8F8F2  normal text
FG_COMMENT='\033[38;2;98;114;164m'  # #6272A4  dim

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
            printf "${FG_PURPLE}${BOLD}Usage:${RESET} cmux-workspace [--claude|-c] [--help|-h]\n"
            printf "\n${FG_COMMENT}Options:${RESET}\n"
            printf "  ${FG_CYAN}--claude, -c${RESET}   Launch Claude Code in the new workspace\n"
            printf "  ${FG_CYAN}--help, -h${RESET}     Show this help\n"
            exit 0
            ;;
        *)
            printf "${FG_ORANGE}${BOLD}✗ Unknown option:${RESET} $1\n" >&2
            printf "Usage: cmux-workspace [--claude|-c]\n" >&2
            exit 1
            ;;
    esac
done

# cmux が利用可能か確認
if [[ ! -x "$CMUX_BIN" ]]; then
    printf "${FG_ORANGE}${BOLD}✗ Error:${RESET} cmux binary not found at $CMUX_BIN\n" >&2
    printf "Ensure cmux is installed and Automation Mode is enabled.\n" >&2
    exit 1
fi

# git リポジトリ内にいるか確認
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    printf "${FG_ORANGE}${BOLD}✗ Error:${RESET} Not in a git repository\n" >&2
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
    printf "${FG_PINK}${BOLD}➕  [新規ブランチを作成]${RESET}\n"

    local worktree_branches
    worktree_branches=$(get_worktree_branches)

    # 既存 worktree のブランチ
    if [[ -n "$worktree_branches" ]]; then
        echo "$worktree_branches" | while read -r b; do
            [[ -n "$b" ]] && printf "${FG_GREEN}${BOLD}🌿 [worktree]${RESET} ${FG_GREEN}${b}${RESET}\n"
        done
    fi

    # ローカルブランチ（worktree に含まれないもの）
    git branch --format='%(refname:short)' | while read -r b; do
        if ! echo "$worktree_branches" | grep -qx "$b" 2>/dev/null; then
            printf "${FG_FG}   ${b}${RESET}\n"
        fi
    done

    # リモートブランチ（ローカルに存在しないもの）
    local local_branches
    local_branches=$(git branch --format='%(refname:short)')
    git branch -r --format='%(refname:short)' 2>/dev/null | grep -v 'HEAD' | sed 's|^origin/||' | while read -r b; do
        if ! echo "$local_branches" | grep -qx "$b" 2>/dev/null && \
           ! echo "$worktree_branches" | grep -qx "$b" 2>/dev/null; then
            printf "${FG_CYAN}🌐 [remote]${RESET}   ${FG_CYAN}${b}${RESET}\n"
        fi
    done
}

# fzf でブランチを選択
selected=$(generate_branch_list | fzf \
    --prompt="  Branch  " \
    --pointer="▶" \
    --marker="✓" \
    --border="rounded" \
    --border-label=" 🌿 cmux-workspace: ${repo_name} " \
    --header=$'🌿 worktree  🌐 remote     local  ➕ new' \
    --height="60%" \
    --min-height="20" \
    --reverse \
    --ansi \
    --color="dark,bg:#282A36,bg+:#44475A,fg:#F8F8F2,fg+:#F8F8F2,hl:#BD93F9,hl+:#BD93F9,border:#6272A4,label:#BD93F9,header:#6272A4,info:#8BE9FD,prompt:#FF79C6,pointer:#FF79C6,marker:#50FA7B,spinner:#FF79C6,separator:#6272A4,preview-bg:#282A36,preview-border:#6272A4,preview-label:#8BE9FD,gutter:#282A36" \
    --preview="
        b=\$(printf '%s' {} | sed \$'s/\033\\\\[[0-9;]*m//g' | sed 's/^[^ ]* //' | sed 's/^\\[worktree\\] //' | sed 's/^\\[remote\\] //')
        if printf '%s' {} | grep -q '新規ブランチを作成'; then
            printf '➕ 新しいブランチを作成します\n'
        else
            git -C '${repo_root}' log --oneline --graph --color=always --decorate -20 \"\$b\" 2>/dev/null \
            || git -C '${repo_root}' log --oneline --graph --color=always --decorate -20 \"origin/\$b\" 2>/dev/null \
            || printf '(no log available)\n'
        fi
    " \
    --preview-window="right:50%:wrap" \
    --preview-label=" 📋 git log " \
    || true)

if [[ -z "$selected" ]]; then
    exit 0
fi

# ANSI エスケープを除去した選択文字列
selected_clean=$(printf '%s' "$selected" | sed $'s/\033\\[[0-9;]*m//g')

# 新規ブランチ作成
if [[ "$selected_clean" == *"[新規ブランチを作成]"* ]]; then
    printf "${FG_PINK}${BOLD}➕ 新しいブランチ名を入力${RESET} ${FG_COMMENT}(空でキャンセル)${RESET}: "
    read -r branch
    if [[ -z "$branch" ]]; then
        printf "${FG_COMMENT}キャンセルしました${RESET}\n"
        exit 1
    fi
    printf "${FG_CYAN}${BOLD}⚙  Creating:${RESET} ${FG_GREEN}${branch}${RESET}\n"
    gwq add -b "$branch" || {
        printf "${FG_ORANGE}${BOLD}✗ Failed:${RESET} ${branch}\n" >&2
        exit 1
    }
    # デフォルトブランチをベースにリセット
    _wt_path=$(get_worktree_path "$branch")
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")
    if [[ -n "$_wt_path" ]] && git rev-parse --verify "$default_branch" &>/dev/null; then
        git -C "$_wt_path" reset --hard "$default_branch" --quiet
        printf "${FG_COMMENT}   Based on: ${FG_YELLOW}${default_branch}${RESET}\n"
    fi
else
    # マークを除去してブランチ名を取得
    branch=$(printf '%s' "$selected" | sed $'s/\033\\[[0-9;]*m//g' | sed 's/^[^ ]* //' | sed 's/^\[worktree\] //' | sed 's/^\[remote\] //')

    # worktree が存在しない場合は作成
    if ! get_worktree_branches | grep -qx "$branch" 2>/dev/null; then
        printf "${FG_CYAN}⚙  Creating worktree:${RESET} ${FG_GREEN}${branch}${RESET}\n"
        gwq add "$branch" 2>/dev/null || {
            printf "${FG_ORANGE}⚠  Remote not found. Creating new branch...${RESET}\n"
            gwq add -b "$branch" || exit 1
        }
    fi
fi

# worktree パスを取得
worktree_path=$(get_worktree_path "$branch")

if [[ -z "$worktree_path" ]]; then
    printf "${FG_ORANGE}${BOLD}✗ Error:${RESET} Could not find worktree path for branch: ${branch}\n" >&2
    exit 1
fi

printf "${FG_PURPLE}${BOLD}🚀 Opening:${RESET} ${FG_GREEN}${branch}${RESET}\n"
printf "${FG_COMMENT}   Path: ${FG_FG}${worktree_path}${RESET}\n"

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

printf "${FG_GREEN}${BOLD}✅ Done:${RESET} ${FG_PURPLE}${workspace_title}${RESET}\n"
