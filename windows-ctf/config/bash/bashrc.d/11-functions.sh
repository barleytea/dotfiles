#!/usr/bin/env bash
# Shell functions (equivalent to functions.zsh, bash-portable version)

# Create directory and cd into it
function mkcd() {
  if [[ -d "$1" ]]; then
    cd "$1"
  else
    mkdir -p "$1" && cd "$1"
  fi
}

# Search and cd into ghq repository (using fzf, bash version of ghq_repository_search)
function ghq_repository_search() {
  if ! command -v ghq >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
    echo "ghq or fzf not found" >&2
    return 1
  fi
  local select
  if command -v bat >/dev/null 2>&1; then
    select=$(ghq list --full-path | fzf --preview "bat --color=always --style=header,grid --line-range :80 {}/README.* 2>/dev/null || ls -la {}")
  else
    select=$(ghq list --full-path | fzf --preview "ls -la {}")
  fi
  if [[ -n "$select" ]]; then
    cd "$select"
  fi
}

# Search and cd into git worktree
function worktree_search() {
  local worktree_dir="${HOME}/worktrees"
  if [[ ! -d "$worktree_dir" ]]; then
    echo "Directory not found: $worktree_dir" >&2
    return 1
  fi
  local select
  select=$(find "$worktree_dir" -name ".git" -exec dirname {} \; | fzf --preview "ls -la {}")
  if [[ -n "$select" ]]; then
    cd "$select"
  fi
}

# AWS SSO profile selector
alias awsp=set_aws_profile
function set_aws_profile() {
  if [[ -n "$AWS_PROFILE" ]]; then
    echo "Current AWS_PROFILE: ${AWS_PROFILE}"
  fi

  local selected_profile
  selected_profile=$(aws configure list-profiles 2>/dev/null |
    grep -v "default" |
    sort |
    fzf --prompt "Select PROFILE. If press Ctrl-C, unset PROFILE. > " \
        --height 50% --layout=reverse --border --preview-window 'right:50%' \
        --preview "grep {} -A5 ~/.aws/config")

  if [[ -z "$selected_profile" ]]; then
    echo "Unset env 'AWS_PROFILE'!"
    unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    unset CDK_DEFAULT_ACCOUNT CDK_DEFAULT_REGION
    return
  fi

  echo "Set the environment variable 'AWS_PROFILE' to '${selected_profile}'!"
  export AWS_PROFILE="$selected_profile"
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

  local check_sso_session
  check_sso_session=$(aws sts get-caller-identity 2>&1)

  if [[ "$check_sso_session" == *"Token has expired"* ]] || [[ "$check_sso_session" == *"Error"* ]]; then
    if [[ "$check_sso_session" == *"Token has expired"* ]]; then
      echo -e "\n----------------------------\nYour Session has expired! Please login...\n----------------------------\n"
    else
      echo -e "\n----------------------------\nAuthentication required. Please login...\n----------------------------\n"
    fi
    local sso_session_name
    sso_session_name=$(grep -A10 "\[profile ${selected_profile}\]" ~/.aws/config | grep "sso_session" | awk '{print $3}' | head -n1)
    if [[ -n "$sso_session_name" ]]; then
      aws sso login --sso-session "${sso_session_name}"
    else
      aws sso login
    fi
    check_sso_session=$(aws sts get-caller-identity 2>&1)
  fi

  if [[ "$check_sso_session" != *"Error"* ]] && [[ "$check_sso_session" != *"Token has expired"* ]]; then
    export CDK_DEFAULT_ACCOUNT="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
    export CDK_DEFAULT_REGION="$(aws configure get region --profile "${selected_profile}" 2>/dev/null)"
    echo -e "\n----------------------------"
    echo "Successfully authenticated!"
    echo "----------------------------"
    echo "AWS Profile: ${AWS_PROFILE}"
    echo "Account ID:  ${CDK_DEFAULT_ACCOUNT}"
    echo "Region:      ${CDK_DEFAULT_REGION}"
    echo "----------------------------"
  else
    echo -e "\nAuthentication failed!"
    echo "${check_sso_session}"
  fi
}
