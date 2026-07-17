# Create directory and cd into it
function mkcd() {
  if [[ -d $1 ]]; then
    cd $1
  else
    mkdir -p $1 && cd $1
  fi
}

# Search and cd into ghq repository (worktrees included when gwq basedir == ghq root)
function ghq_repository_search() {
  local select=$(ghq list --full-path | fzf \
    --preview "bat --color=always --style=header,grid --line-range :80 {}/README.* 2>/dev/null || ls -la {}")
  if [[ -n "$select" ]]; then
    cd "$select"
    zle reset-prompt
  fi
}

# Search command history
function peco_select_history() {
  local select=$(history | fzf)
  if [[ -n "$select" ]]; then
    BUFFER="$select"
    zle accept-line
  fi
}

zle -N ghq_repository_search

# Search and cd into git worktree (gwq basedir == ghq root, worktrees have '=' in path)
function worktree_search() {
  local select=$(ghq list --full-path | grep '=' | fzf --preview "ls -la {}")
  if [[ -n "$select" ]]; then
    cd "$select"
    zle reset-prompt
  fi
}

zle -N worktree_search

# Launch Claude Code with --add-dir (fzf multi-select from ghq + worktrees)
function claude_add_dir_search() {
  local current_dir=$(pwd -P)

  local candidates=$(ghq list --full-path 2>/dev/null | grep -v "^${current_dir}$")

  local selected=$(echo "$candidates" | fzf --multi \
    --prompt="Add dirs (Tab=select, Enter=confirm) > " \
    --header="Main: ${current_dir}" \
    --preview "bat --color=always --style=header,grid --line-range :80 {}/README.* 2>/dev/null || ls -la {}" \
    --height=60% --reverse --border)

  if [[ -n "$selected" ]]; then
    local add_dir_args=""
    while IFS= read -r dir; do
      [[ -n "$dir" ]] && add_dir_args+=" --add-dir ${(q)dir}"
    done <<< "$selected"
    BUFFER="claude${add_dir_args}"
    zle accept-line
  fi
}

zle -N claude_add_dir_search

# Launch Claude Code through pxpipe-proxy (opt-in token-saving image compression, see /pxpipe-guide)
function claude-px() {
  local pxpipe_port=47821
  if ! curl -s -o /dev/null "http://127.0.0.1:${pxpipe_port}/"; then
    echo "[claude-px] starting pxpipe-proxy on :${pxpipe_port}"
    pxpipe-proxy &>/dev/null &
    disown
    sleep 1
  fi
  ANTHROPIC_BASE_URL="http://127.0.0.1:${pxpipe_port}" claude "$@"
}

# AWS SSO
alias awsp=set_aws_profile
function set_aws_profile() {
  # 現在のプロファイルを表示
  if [[ -n "$AWS_PROFILE" ]]; then
    echo "Current AWS_PROFILE: ${AWS_PROFILE}"
  fi

  # Select AWS PROFILE
  local selected_profile=$(aws configure list-profiles |
    grep -v "default" |
    sort |
    fzf --prompt "Select PROFILE. If press Ctrl-C, unset PROFILE. > " \
        --height 50% --layout=reverse --border --preview-window 'right:50%' \
        --preview "grep {} -A5 ~/.aws/config")

  # プロファイルが選択されなかった場合は環境変数をクリア
  if [ -z "$selected_profile" ]; then
    echo "Unset env 'AWS_PROFILE'!"
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset CDK_DEFAULT_ACCOUNT
    unset CDK_DEFAULT_REGION
    return
  fi

  # プロファイルを設定
  echo "Set the environment variable 'AWS_PROFILE' to '${selected_profile}'!"
  export AWS_PROFILE="$selected_profile"
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  # SSO session名を環境変数から取得、なければconfigから自動検出
  local sso_session_name="${AWS_SSO_SESSION_NAME}"
  if [ -z "$sso_session_name" ]; then
    sso_session_name=$(grep -A10 "\[profile ${selected_profile}\]" ~/.aws/config | grep "sso_session" | awk '{print $3}' | head -n1)
  fi

  # SSOセッションのチェック
  local check_sso_session=$(aws sts get-caller-identity 2>&1)

  if [[ "$check_sso_session" == *"Token has expired"* ]] || [[ "$check_sso_session" == *"Error"* ]]; then
    # セッションが切れているか、エラーの場合は再ログイン
    if [[ "$check_sso_session" == *"Token has expired"* ]]; then
      echo -e "\n----------------------------\nYour Session has expired! Please login...\n----------------------------\n"
    else
      echo -e "\n----------------------------\nAuthentication required. Please login...\n----------------------------\n"
    fi

    # SSO session名が取得できた場合はそれを使用
    if [[ -n "$sso_session_name" ]]; then
      aws sso login --sso-session "${sso_session_name}"
    else
      aws sso login
    fi

    # ログイン後に再度認証情報を確認
    check_sso_session=$(aws sts get-caller-identity 2>&1)
  fi

  # 認証成功時にCDK環境変数を設定
  if [[ "$check_sso_session" != *"Error"* ]] && [[ "$check_sso_session" != *"Token has expired"* ]]; then
    export CDK_DEFAULT_ACCOUNT="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
    export CDK_DEFAULT_REGION="$(aws configure get region --profile "${selected_profile}" 2>/dev/null)"

    echo -e "\n----------------------------"
    echo "✅ Successfully authenticated!"
    echo "----------------------------"
    echo "AWS Profile: ${AWS_PROFILE}"
    echo "Account ID:  ${CDK_DEFAULT_ACCOUNT}"
    echo "Region:      ${CDK_DEFAULT_REGION}"
    echo "----------------------------\n"
  else
    echo -e "\n❌ Authentication failed!"
    echo "${check_sso_session}"
  fi
}
