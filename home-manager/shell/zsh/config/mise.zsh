# mise (旧 rtx) 初期化設定
# https://mise.jdx.dev/getting-started.html

# mise の初期化
if [[ -x "$(command -v mise)" ]]; then
  eval "$(mise activate zsh)"
  
  # mise の補完設定
  if [[ -d "$HOME/.local/share/mise/completions" ]]; then
    fpath=("$HOME/.local/share/mise/completions" $fpath)
  fi
fi

# mise 用の環境変数
export MISE_USE_TOML=1
export MISE_EXPERIMENTAL=1

# mise データディレクトリを XDG Base Directory に準拠
export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
export MISE_CONFIG_DIR="$XDG_CONFIG_HOME/mise"
export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"
