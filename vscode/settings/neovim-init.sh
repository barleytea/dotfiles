#!/usr/bin/env bash
# VS Code起動時にNeovim設定を初期化するスクリプト

set -euo pipefail

# 環境変数の設定
HOME_DIR="$HOME"
DOTFILES_DIR="$HOME/git_repos/github.com/barleytea/dotfiles"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
VSCODE_SETTINGS_DIR="$DOTFILES_DIR/vscode/settings"

# ログ関数
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# vscode.luaファイルのパス
VSCODE_LUA="$NVIM_CONFIG_DIR/vscode.lua"

# vscode.luaファイルがない場合は作成
if [ ! -f "$VSCODE_LUA" ]; then
  log "Creating VSCode-Neovim initialization file: $VSCODE_LUA"

  # ディレクトリが存在しない場合は作成
  mkdir -p "$NVIM_CONFIG_DIR"

  # vscode.luaファイルを作成
  cat > "$VSCODE_LUA" << 'EOF'
-- VSCode-Neovim連携モード設定ファイル
-- このファイルはVS Codeから起動されたNeovimの設定ファイルです

-- VSCodeモードフラグを設定
vim.g.vscode = 1

-- 基本的なオプション設定（最小限）
vim.opt.compatible = false     -- Vi互換モードをオフ
vim.opt.backup = false         -- バックアップファイルを作成しない
vim.opt.writebackup = false    -- 書き込み時のバックアップを作成しない
vim.opt.swapfile = false       -- スワップファイルを作成しない
vim.opt.updatetime = 50        -- 更新間隔を短く
vim.opt.timeoutlen = 300       -- キーマップのタイムアウト時間
vim.opt.clipboard = "unnamedplus"  -- クリップボード連携
vim.opt.ignorecase = true      -- 検索時に大文字小文字を区別しない
vim.opt.smartcase = true       -- 検索パターンに大文字が含まれる場合は区別する

-- キーマップ設定
-- 標準のキーマップは残しつつ、競合しやすい部分だけオーバーライド
vim.g.mapleader = " "          -- リーダーキーをスペースに設定

-- VSCode-Neovim拡張機能との連携のための設定
-- 特殊コマンドは<Cmd>call VSCodeNotify()形式で実行
vim.api.nvim_set_keymap('n', '<C-j>', '<Cmd>call VSCodeNotify("workbench.action.navigateDown")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>', '<Cmd>call VSCodeNotify("workbench.action.navigateUp")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-h>', '<Cmd>call VSCodeNotify("workbench.action.navigateLeft")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>', '<Cmd>call VSCodeNotify("workbench.action.navigateRight")<CR>', { noremap = true, silent = true })

-- 一般的なキーバインディングもVSCode向けに最適化
vim.api.nvim_set_keymap('n', 'gd', '<Cmd>call VSCodeNotify("editor.action.revealDefinition")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gr', '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gi', '<Cmd>call VSCodeNotify("editor.action.goToImplementation")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>f', '<Cmd>call VSCodeNotify("workbench.action.quickOpen")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>w', '<Cmd>call VSCodeNotify("workbench.action.files.save")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>e', '<Cmd>call VSCodeNotify("workbench.view.explorer")<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>q', '<Cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<CR>', { noremap = true, silent = true })

-- 起動完了メッセージ
print("VSCode-Neovim mode initialized")

EOF

  log "VSCode-Neovim initialization file created successfully."
else
  log "Using existing VSCode-Neovim initialization file: $VSCODE_LUA"
fi

# VSCode設定ファイルの更新（neovim関連の設定を更新）
SETTINGS_JSON="$VSCODE_SETTINGS_DIR/settings.json"

# 設定ファイルがないか空の場合、バックアップから復元
if [ ! -s "$SETTINGS_JSON" ] && [ -s "$SETTINGS_JSON.bak" ]; then
  log "settings.json is empty, restoring from backup..."
  cp "$SETTINGS_JSON.bak" "$SETTINGS_JSON"
fi

if [ -f "$SETTINGS_JSON" ]; then
  # settings.jsonの存在確認
  log "Updating VSCode settings to use the VSCode-Neovim initialization file..."

  # バックアップを作成（ファイルが存在し、内容がある場合のみ）
  if [ -s "$SETTINGS_JSON" ]; then
    cp "$SETTINGS_JSON" "$SETTINGS_JSON.bak"
    log "Backup created at $SETTINGS_JSON.bak"
  fi

  # jqがインストールされているか確認
  if command -v jq &> /dev/null; then
    # コメントを含むJSONの処理方法
    # 1. 一時ファイルにコピー
    TEMP_JSON=$(mktemp)
    cp "$SETTINGS_JSON" "$TEMP_JSON"

    # 2. コメント行を削除して有効なJSONにする（簡易的な方法）
    VALID_JSON=$(mktemp)
    grep -v '//' "$TEMP_JSON" > "$VALID_JSON"

    # 3. jqを使用して設定を更新
    if jq --arg path "$VSCODE_LUA" \
      '.["vscode-neovim.neovimInitVimPaths.darwin"] = $path' \
      "$VALID_JSON" > "$TEMP_JSON.new" 2>/dev/null; then

      # 4. 更新が成功したら、元のファイルに書き戻す
      mv "$TEMP_JSON.new" "$SETTINGS_JSON"
      log "VSCode settings updated successfully with jq."
    else
      # jqでエラーが発生した場合は、手動で更新を試みる
      log "Warning: Error processing JSON with jq. Attempting manual update..."

      # 5. 手動での置換（sed等を使用）
      if grep -q "vscode-neovim.neovimInitVimPaths.darwin" "$SETTINGS_JSON"; then
        # 既存の設定を更新
        sed -i '' "s|\"vscode-neovim.neovimInitVimPaths.darwin\":[^,]*|\"vscode-neovim.neovimInitVimPaths.darwin\": \"$VSCODE_LUA\"|" "$SETTINGS_JSON"
      else
        # 設定が存在しない場合は追加（簡易的な方法）
        sed -i '' "s|{|{\n    \"vscode-neovim.neovimInitVimPaths.darwin\": \"$VSCODE_LUA\",|" "$SETTINGS_JSON"
      fi
      log "VSCode settings manually updated."
    fi

    # 一時ファイルの削除
    rm -f "$TEMP_JSON" "$VALID_JSON" 2>/dev/null || true
  else
    log "Warning: jq command not found. Attempting manual update..."

    # jqがない場合は手動で更新を試みる
    if grep -q "vscode-neovim.neovimInitVimPaths.darwin" "$SETTINGS_JSON"; then
      # 既存の設定を更新
      sed -i '' "s|\"vscode-neovim.neovimInitVimPaths.darwin\":[^,]*|\"vscode-neovim.neovimInitVimPaths.darwin\": \"$VSCODE_LUA\"|" "$SETTINGS_JSON"
    else
      # 設定が存在しない場合は追加（簡易的な方法）
      sed -i '' "s|{|{\n    \"vscode-neovim.neovimInitVimPaths.darwin\": \"$VSCODE_LUA\",|" "$SETTINGS_JSON"
    fi
    log "VSCode settings manually updated."
  fi
else
  log "Warning: VSCode settings file not found at $SETTINGS_JSON"
  log "Creating minimal settings file..."

  # 最小限の設定ファイルを作成
  cat > "$SETTINGS_JSON" << EOF
{
    "vscode-neovim.neovimExecutablePaths.darwin": "/Users/miyoshi_s/.local/state/nix/profiles/profile/bin/nvim",
    "vscode-neovim.neovimInitVimPaths.darwin": "$VSCODE_LUA"
}
EOF
  log "Minimal VSCode settings file created."
fi

# 設定の同期 - Home Managerインストール版かローカル版を使用
log "Checking for synchronization script..."

# ローカルの同期スクリプト
LOCAL_SYNC_SCRIPT="$VSCODE_SETTINGS_DIR/sync.sh"

# 同期スクリプトが存在する場合は実行
SYNC_SCRIPT="$HOME/.local/bin/sync-editor-settings"
if [ -f "$SYNC_SCRIPT" ]; then
  log "Running Home Manager synchronization script..."
  # タイムアウト付きで実行 (30秒)
  timeout 30s "$SYNC_SCRIPT" || log "Warning: Synchronization script timed out"
elif [ -f "$LOCAL_SYNC_SCRIPT" ]; then
  log "Running local synchronization script..."
  # タイムアウト付きで実行 (30秒)
  timeout 30s bash "$LOCAL_SYNC_SCRIPT" || log "Warning: Local synchronization script timed out"
else
  log "No synchronization script found. Skipping synchronization."
  log "To synchronize settings, run 'make vscode-sync' after this script completes."
fi

log "VSCode-Neovim initialization complete."
log "Please restart VS Code for the changes to take effect."
