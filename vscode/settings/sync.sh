#!/usr/bin/env bash
# VSCodeとNeovimの設定を同期するためのシンプルなスクリプト
# このスクリプトはHome Manager経由でインストールされるsync-editor-settingsをシンプル化したものです

set -euo pipefail

# 環境変数の設定
HOME_DIR="$HOME"
DOTFILES_DIR="$HOME/git_repos/github.com/barleytea/dotfiles"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
VSCODE_SETTINGS_DIR="$DOTFILES_DIR/vscode/settings"
NVIM_LUA_DIR="$NVIM_CONFIG_DIR/lua"

# ログ関数
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# バックアップを作成
backup_file() {
  if [ -f "$1" ]; then
    cp "$1" "$1.bak"
    log "バックアップを作成しました: $1.bak"
  fi
}

# ディレクトリの存在確認と作成
check_and_create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    log "ディレクトリを作成しました: $1"
  fi
}

# VSCode設定からNeovim設定への同期
sync_vscode_to_neovim() {
  log "VSCodeからNeovimへの設定同期を開始..."

  # Neovimの設定ディレクトリを確認
  check_and_create_dir "$NVIM_LUA_DIR/shared"

  # VSCodeのキーマップ設定を読み込んでNeovimの設定に変換
  if [ -f "$VSCODE_SETTINGS_DIR/neovim-keymaps.json" ]; then
    # バックアップを作成
    backup_file "$NVIM_LUA_DIR/shared/keymaps.lua"

    log "Neovimキーマップファイルを生成しています..."
    cat > "$NVIM_LUA_DIR/shared/keymaps.lua" << 'EOL'
-- VSCodeとの同期で生成されたキーマップファイル
-- 警告: このファイルは自動生成されます。手動編集はバックアップを取ってから行ってください。

local M = {}

function M.setup()
  -- リーダーキーの設定
  vim.g.mapleader = " "

  -- 基本的なキーマッピング
  -- エディタ操作
  vim.keymap.set('n', '<leader>w', ':w<CR>', { silent = true, desc = "保存" })
  vim.keymap.set('n', '<leader>q', ':q<CR>', { silent = true, desc = "終了" })
  vim.keymap.set('i', 'jj', '<Esc>', { silent = true, desc = "ESCキー" })

  -- 移動キー
  vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true, desc = "左ウィンドウへ移動" })
  vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true, desc = "下ウィンドウへ移動" })
  vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true, desc = "上ウィンドウへ移動" })
  vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true, desc = "右ウィンドウへ移動" })

  -- タブ/バッファ操作
  vim.keymap.set('n', '<S-h>', ':bprevious<CR>', { silent = true, desc = "前のバッファ" })
  vim.keymap.set('n', '<S-l>', ':bnext<CR>', { silent = true, desc = "次のバッファ" })

  -- VSCode特有の設定（VSCodeから呼び出されたときのみ適用）
  if vim.g.vscode then
    -- VSCode特有のキーマッピングを上書き
    vim.keymap.set('n', '<C-h>', '<Cmd>call VSCodeNotify("workbench.action.navigateLeft")<CR>', { silent = true })
    vim.keymap.set('n', '<C-j>', '<Cmd>call VSCodeNotify("workbench.action.navigateDown")<CR>', { silent = true })
    vim.keymap.set('n', '<C-k>', '<Cmd>call VSCodeNotify("workbench.action.navigateUp")<CR>', { silent = true })
    vim.keymap.set('n', '<C-l>', '<Cmd>call VSCodeNotify("workbench.action.navigateRight")<CR>', { silent = true })

    -- 編集操作
    vim.keymap.set('n', '<leader>w', '<Cmd>call VSCodeNotify("workbench.action.files.save")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>q', '<Cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>e', '<Cmd>call VSCodeNotify("workbench.view.explorer")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>f', '<Cmd>call VSCodeNotify("workbench.action.quickOpen")<CR>', { silent = true })

    -- コード操作
    vim.keymap.set('n', 'gd', '<Cmd>call VSCodeNotify("editor.action.revealDefinition")<CR>', { silent = true })
    vim.keymap.set('n', 'gr', '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>', { silent = true })
  end
end

return M
EOL
    log "Neovimキーマップファイルを更新しました"
  else
    log "警告: VSCode用のneovim-keymaps.jsonが見つかりません"
  fi

  # VSCode設定ファイルからNeovim設定ファイルを生成
  if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    # バックアップを作成
    backup_file "$NVIM_LUA_DIR/shared/options.lua"

    log "Neovim設定ファイルを生成しています..."
    cat > "$NVIM_LUA_DIR/shared/options.lua" << 'EOL'
-- VSCodeからの同期で生成された設定ファイル
-- 警告: このファイルは自動生成されます。手動編集はバックアップを取ってから行ってください。

local M = {}

function M.setup()
  -- 基本設定
  vim.opt.number = true          -- 行番号表示
  vim.opt.relativenumber = true  -- 相対行番号
  vim.opt.cursorline = true      -- カーソル行をハイライト
  vim.opt.cursorcolumn = true    -- カーソル列をハイライト
  vim.opt.wrap = false           -- 行の折り返しをしない
  vim.opt.tabstop = 2            -- タブ幅
  vim.opt.shiftwidth = 2         -- インデント幅
  vim.opt.expandtab = true       -- タブをスペースに展開
  vim.opt.smartindent = true     -- スマートインデント
  vim.opt.autoindent = true      -- 自動インデント

  -- 検索設定
  vim.opt.hlsearch = true        -- 検索結果のハイライト
  vim.opt.ignorecase = true      -- 大文字小文字を区別しない
  vim.opt.smartcase = true       -- 検索語に大文字が含まれる場合は区別

  -- システム設定
  vim.opt.backup = false         -- バックアップファイルを作成しない
  vim.opt.writebackup = false    -- 書き込み時のバックアップを作成しない
  vim.opt.swapfile = false       -- スワップファイルを作成しない
  vim.opt.updatetime = 50        -- 更新間隔
  vim.opt.clipboard = "unnamedplus" -- クリップボード連携

  -- VSCodeモードでの特殊設定
  if vim.g.vscode then
    -- VSCodeでは一部の設定を上書き
    vim.opt.hlsearch = false     -- VSCode側でハイライト
    vim.opt.cursorline = false   -- VSCode側でハイライト
    vim.opt.cursorcolumn = false -- VSCode側でハイライト
  end
end

return M
EOL
    log "Neovim設定ファイルを更新しました"
  else
    log "警告: VSCode用のsettings.jsonが見つかりません"
  fi

  # vscode.luaファイルの生成
  backup_file "$NVIM_CONFIG_DIR/vscode.lua"
  log "VSCode Neovimモード用の初期化ファイルを更新しています..."

  cat > "$NVIM_CONFIG_DIR/vscode.lua" << 'EOL'
-- VSCode-Neovim連携モード設定ファイル
-- このファイルはVS Codeから起動されたNeovimの設定ファイルです

-- VSCodeモードフラグを設定
vim.g.vscode = 1

-- 共有設定を読み込み
local ok, options = pcall(require, 'shared.options')
if ok then
  options.setup()
else
  print("Warning: オプション設定の読み込みに失敗しました")
end

local ok, keymaps = pcall(require, 'shared.keymaps')
if ok then
  keymaps.setup()
else
  print("Warning: キーマップ設定の読み込みに失敗しました")
end

-- VSCodeモード専用の設定
-- エスケープシーケンスの高速化
vim.opt.ttimeoutlen = 0

print("VSCode-Neovim mode initialized")
EOL
  log "VSCode Neovimモード初期化ファイルを更新しました"

  # init.luaにVSCodeモード設定を追加する処理
  # まず存在チェックと書き込み権限チェックを分離
  if [ -f "$NVIM_CONFIG_DIR/init.lua" ]; then
    log "既存のinit.luaが見つかりました"
    # 書き込み権限チェック
    if [ -w "$NVIM_CONFIG_DIR/init.lua" ]; then
      # 書き込み可能な場合
      backup_file "$NVIM_CONFIG_DIR/init.lua"

      # すでに共有設定が含まれているか確認
      if grep -q "require('shared.keymaps')" "$NVIM_CONFIG_DIR/init.lua" || \
         grep -q "require('shared.options')" "$NVIM_CONFIG_DIR/init.lua"; then
        log "init.luaにはすでに共有設定が含まれています"
      else
        # 書き込み可能で共有設定がない場合は追加
        log "init.luaに共有設定を追加しています..."

        cat >> "$NVIM_CONFIG_DIR/init.lua" << 'EOL'

-- VSCodeとの共有設定（自動生成）
if not vim.g.vscode then
  -- VSCodeモードでない場合のみ読み込み
  pcall(function() require('shared.options').setup() end)
  pcall(function() require('shared.keymaps').setup() end)
end
EOL
        log "init.luaを更新しました"
      fi
    else
      # 書き込み権限がない場合
      log "警告: init.luaファイルが書き込み保護されています（nixで管理されている可能性）"
      log "手動で以下の設定をinit.luaに追加することを推奨します:"
      cat << 'EOL'
-- 追加すべき設定:
if not vim.g.vscode then
  -- VSCodeモードでない場合のみ読み込み
  pcall(function() require('shared.options').setup() end)
  pcall(function() require('shared.keymaps').setup() end)
end
EOL
    fi
  elif [ -w "$NVIM_CONFIG_DIR" ]; then
    # init.luaが存在せず、ディレクトリが書き込み可能な場合は新規作成
    log "init.luaが見つからないため、新規作成します"
    cat > "$NVIM_CONFIG_DIR/init.lua" << 'EOL'
-- Neovim設定ファイル
-- VSCodeとの同期で一部設定が自動生成されます

-- 基本設定
vim.g.mapleader = " "  -- スペースをリーダーキーに設定

-- VSCodeモードチェック
if not vim.g.vscode then
  -- VSCodeモードでない場合のみ読み込み
  pcall(function() require('shared.options').setup() end)
  pcall(function() require('shared.keymaps').setup() end)

  -- 通常のNeovim用設定をここに追加
end
EOL
    log "init.luaを新規作成しました"
  else
    # init.luaが存在せず、ディレクトリも書き込み不可の場合
    log "警告: init.luaを作成できません。ディレクトリが書き込み保護されています"
    log "手動で設定を追加する必要があります"
  fi

  log "VSCodeからNeovimへの設定同期が完了しました"
}

# Neovim設定からVSCode設定への同期（基本的な部分のみ）
sync_neovim_to_vscode() {
  log "NeovimからVSCodeへの基本設定同期を開始..."

  # VSCode設定ディレクトリがあるか確認
  check_and_create_dir "$VSCODE_SETTINGS_DIR"

  # VSCode設定ファイルのバックアップ
  if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    backup_file "$VSCODE_SETTINGS_DIR/settings.json"
  fi

  # 設定ファイルが存在しない場合、最低限の設定を生成
  if [ ! -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    cat > "$VSCODE_SETTINGS_DIR/settings.json" << EOL
{
    "workbench.colorTheme": "Dracula Theme",
    "editor.fontFamily": "'Hack Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace",
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.wordWrap": "off",
    "terminal.integrated.fontFamily": "'Hack Nerd Font Mono'",
    "vscode-neovim.neovimExecutablePaths.darwin": "$HOME/.local/state/nix/profiles/profile/bin/nvim",
    "vscode-neovim.neovimInitVimPaths.darwin": "$NVIM_CONFIG_DIR/vscode.lua"
}
EOL
    log "基本的なVSCode設定ファイルを生成しました"
  else
    # jqがインストールされているか確認
    if command -v jq &> /dev/null; then
      # VSCodeの設定に適切なNeovimパスを設定
      jq --arg path "$NVIM_CONFIG_DIR/vscode.lua" \
        '.["vscode-neovim.neovimInitVimPaths.darwin"] = $path' \
        "$VSCODE_SETTINGS_DIR/settings.json.bak" > "$VSCODE_SETTINGS_DIR/settings.json"
      log "VSCode設定ファイルを更新しました"
    else
      log "警告: jqコマンドが見つかりません。設定の自動更新ができません。"
      log "手動で $VSCODE_SETTINGS_DIR/settings.json を編集してください。"
    fi
  fi

  log "NeovimからVSCodeへの設定同期が完了しました"
}

# メイン処理
log "VSCode-Neovim設定同期を開始します..."

# VSCode -> Neovim 方向の同期
sync_vscode_to_neovim

# Neovim -> VSCode 方向の同期
sync_neovim_to_vscode

log "設定同期が完了しました。VSCodeとNeovimを再起動して変更を反映してください。"
