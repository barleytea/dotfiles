# mise 初期化設定
# https://mise.jdx.dev/getting-started.html

# mise の初期化（非対話シェルでは activate しない）
if [[ -o interactive ]] && [[ -x "$(command -v mise)" ]]; then
  eval "$(mise activate zsh)"

  # mise の補完設定
  if [[ -d "$MISE_DATA_DIR/completions" ]]; then
    fpath=("$MISE_DATA_DIR/completions" $fpath)
  fi
fi

# safe-chain: npm/pip/bun 等をラップしてサプライチェーン攻撃を防御
# `mise run safe-chain-setup` でセットアップ済みの場合のみ有効
if [[ -f "$HOME/.safe-chain/scripts/init-posix.sh" ]]; then
  source "$HOME/.safe-chain/scripts/init-posix.sh"
fi
