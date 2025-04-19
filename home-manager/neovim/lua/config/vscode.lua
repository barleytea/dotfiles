-- VSCode連携モード用の設定ファイル

-- VSCodeモードかどうかを判定する関数
local function is_vscode()
  return vim.g.vscode == 1
end

-- VSCodeモード時のみ設定を適用するヘルパー関数
local function vscode_only(fn)
  if is_vscode() then
    fn()
  end
end

-- 通常のNeovimでのみ設定を適用するヘルパー関数
local function neovim_only(fn)
  if not is_vscode() then
    fn()
  end
end

-- 共通設定
-- VSCode環境でもNeovim環境でも必要な基本設定
local function apply_common_settings()
  -- 基本的なオプション設定
  vim.opt.clipboard = "unnamedplus"  -- クリップボード連携
  vim.opt.ignorecase = true          -- 検索時に大文字・小文字を区別しない
  vim.opt.smartcase = true           -- 検索パターンに大文字が含まれる場合は区別する
  vim.opt.hlsearch = true            -- 検索結果をハイライト

  -- 競合しないキーマッピング（共通設定）
  vim.api.nvim_set_keymap('i', 'jj', '<Esc><Esc><Esc>', { noremap = true })
  vim.g.mapleader = " "  -- リーダーキーをスペースに設定
end

-- VSCodeモード専用の設定
local function apply_vscode_settings()
  -- VSCodeモード時は不要な視覚的な設定を無効化
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = "no"
  vim.opt.cursorline = false
  vim.opt.cursorcolumn = false

  -- VSCode環境ではtコマンドが動作しないため、コマンドを上書き
  vim.api.nvim_set_keymap('n', 't', '<Nop>', { noremap = true })

  -- VSCode独自のアクションにマッピング
  vim.api.nvim_set_keymap('n', 'gd', '<Cmd>call VSCodeNotify("editor.action.revealDefinition")<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', 'gr', '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', 'gi', '<Cmd>call VSCodeNotify("editor.action.goToImplementation")<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', '<C-k>', '<Cmd>call VSCodeNotify("workbench.action.navigateUp")<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', '<C-j>', '<Cmd>call VSCodeNotify("workbench.action.navigateDown")<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', '<C-h>', '<Cmd>call VSCodeNotify("workbench.action.navigateLeft")<CR>', { noremap = true, silent = true })
  vim.api.nvim_set_keymap('n', '<C-l>', '<Cmd>call VSCodeNotify("workbench.action.navigateRight")<CR>', { noremap = true, silent = true })

  -- エスケープキーの動作を上書き（ハイライト解除の動作を無効化）
  vim.api.nvim_set_keymap('n', '<Esc>', '<Esc>', { noremap = true })

  -- コロンとセミコロンの置き換えを無効化（VSCodeでの操作性向上のため）
  vim.api.nvim_del_keymap('n', ':')
  vim.api.nvim_del_keymap('n', ';')
end

-- Neovim専用の設定（VSCodeでは適用しない）
local function apply_neovim_settings()
  -- 純粋なNeovimモードの場合のみ必要な設定
  vim.opt.termguicolors = true
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.cursorline = true
  vim.opt.cursorcolumn = true

  -- プラグイン関連の設定もここに追加
  -- 例：vim-airlineの設定など
end

-- すべての設定を適用
local function apply_all_settings()
  -- 常に共通設定を適用
  apply_common_settings()

  -- VSCodeモードかどうかで分岐
  if is_vscode() then
    apply_vscode_settings()
  else
    apply_neovim_settings()
  end

  -- VSCodeモードであることをログに出力（デバッグ用）
  if is_vscode() then
    print("VSCode-Neovim mode activated")
  end
end

-- 設定を適用
apply_all_settings()

-- コマンドを定義
vim.api.nvim_create_user_command('VSCodeKeymap', function()
  print("VSCode-Neovim keymaps are active")
  -- 現在のキーマップを表示するコードをここに追加可能
end, {})

-- グローバルにエクスポート
return {
  is_vscode = is_vscode,
  vscode_only = vscode_only,
  neovim_only = neovim_only
}
