#!/usr/bin/env bash
# herdr 内で zellij が二重起動する問題の切り分け用診断スクリプト（一時ファイル、コミット不要）
set -uo pipefail

section() { echo; echo "=== $1 ==="; }

section "ZDOTDIR"
echo "ZDOTDIR=${ZDOTDIR:-<unset>}"

section "zellij.zsh の実体パス（ZDOTDIR配下）"
if [ -n "${ZDOTDIR:-}" ] && [ -f "$ZDOTDIR/config/zellij.zsh" ]; then
  readlink -f "$ZDOTDIR/config/zellij.zsh"
else
  echo "(ZDOTDIR/config/zellij.zsh が見つからない)"
fi

section "デプロイ済み zellij.zsh に HERDR_ENV チェックが入っているか"
if [ -n "${ZDOTDIR:-}" ] && [ -f "$ZDOTDIR/config/zellij.zsh" ]; then
  grep -n "HERDR_ENV\|Alacrittyの場合のみ" "$ZDOTDIR/config/zellij.zsh" || echo "(該当行なし = 修正が反映されていない)"
else
  find / -xdev -name "zellij.zsh" 2>/dev/null | while read -r f; do
    echo "--- $f ---"
    grep -n "HERDR_ENV" "$f" || echo "(HERDR_ENV なし)"
  done
fi

section "~/.zshrc のシンボリックリンク先"
readlink -f ~/.zshrc 2>&1

section "評価時点の環境変数"
echo "ZELLIJ=[${ZELLIJ:-}]"
echo "HERDR_ENV=[${HERDR_ENV:-}]"
echo "TERM_PROGRAM=[${TERM_PROGRAM:-}]"
echo "ALACRITTY_SOCKET=[${ALACRITTY_SOCKET:-}]"
echo "HERDR_PANE_ID=[${HERDR_PANE_ID:-}]"

section "現在の zellij セッション一覧"
zellij list-sessions 2>&1

section "プロセスツリー（herdr / zellij / zsh の親子関係を確認）"
ps -eo pid,ppid,comm --forest 2>&1 | grep -i "herdr\|zellij\|zsh"

section "done"
