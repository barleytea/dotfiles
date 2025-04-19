-- VSCode連携用のNeovim設定ファイル
-- このファイルはVSCodeからNeovimを起動する際に使用される

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

-- Escで検索ハイライトをクリア（VSCodeネイティブの機能を使用）
vim.api.nvim_set_keymap('n', '<Esc>', '<Cmd>call VSCodeNotify("search.action.clearHighlight")<CR>', { noremap = true, silent = true })

-- コロンとセミコロンの入れ替えをVSCodeモードでは無効化（VSCode操作に干渉するため）
-- もともとの設定があればそれを無効化
pcall(function() vim.keymap.del('n', ':') end)
pcall(function() vim.keymap.del('n', ';') end)

-- インサートモードでの矢印キー移動をVSCode標準に合わせる
vim.api.nvim_set_keymap('i', '<C-h>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-j>', '<Down>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-k>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-l>', '<Right>', { noremap = true })

-- コマンドモードと検索モードでの矢印キー移動
vim.api.nvim_set_keymap('c', '<C-h>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-j>', '<Down>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-k>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-l>', '<Right>', { noremap = true })

-- オムニ補完をVSCode標準に合わせる
vim.api.nvim_set_keymap('i', '<C-Space>', '<Cmd>call VSCodeNotify("editor.action.triggerSuggest")<CR>', { noremap = true, silent = true })

-- 起動完了メッセージ
print("VSCode-Neovim optimized mode initialized")

-- utils/keymapsモジュールを読み込む
local ok, keymap_utils = pcall(require, 'utils.keymaps')
if ok then
  -- 高度なキーマッピングユーティリティが使用可能（推奨）
  print("Keymap utilities loaded")
end

-- config/vscodeモジュールを読み込む
local ok, vscode_config = pcall(require, 'config.vscode')
if ok then
  -- VSCode専用設定が正常に読み込まれた
  print("VSCode-specific configuration loaded")
end
