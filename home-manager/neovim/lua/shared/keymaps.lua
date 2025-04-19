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
