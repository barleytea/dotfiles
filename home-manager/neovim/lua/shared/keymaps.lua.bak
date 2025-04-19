-- Keymap file generated from VSCode sync
-- Warning: This file is auto-generated. Take backup before manual editing.

local M = {}

function M.setup()
  -- Leader key setting
  vim.g.mapleader = " "

  -- Basic keymappings
  -- Editor operations
  vim.keymap.set('n', '<leader>w', ':w<CR>', { silent = true, desc = "Save" })
  vim.keymap.set('n', '<leader>q', ':q<CR>', { silent = true, desc = "Quit" })
  vim.keymap.set('i', 'jj', '<Esc>', { silent = true, desc = "ESC key" })

  -- Movement keys
  vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true, desc = "Move to left window" })
  vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true, desc = "Move to window below" })
  vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true, desc = "Move to window above" })
  vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true, desc = "Move to right window" })

  -- Tab/Buffer operations
  vim.keymap.set('n', '<S-h>', ':bprevious<CR>', { silent = true, desc = "Previous buffer" })
  vim.keymap.set('n', '<S-l>', ':bnext<CR>', { silent = true, desc = "Next buffer" })

  -- VSCode-specific settings (applied only when called from VSCode)
  if vim.g.vscode then
    -- Override VSCode-specific keymappings
    vim.keymap.set('n', '<C-h>', '<Cmd>call VSCodeNotify("workbench.action.navigateLeft")<CR>', { silent = true })
    vim.keymap.set('n', '<C-j>', '<Cmd>call VSCodeNotify("workbench.action.navigateDown")<CR>', { silent = true })
    vim.keymap.set('n', '<C-k>', '<Cmd>call VSCodeNotify("workbench.action.navigateUp")<CR>', { silent = true })
    vim.keymap.set('n', '<C-l>', '<Cmd>call VSCodeNotify("workbench.action.navigateRight")<CR>', { silent = true })

    -- Edit operations
    vim.keymap.set('n', '<leader>w', '<Cmd>call VSCodeNotify("workbench.action.files.save")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>q', '<Cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>e', '<Cmd>call VSCodeNotify("workbench.view.explorer")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>f', '<Cmd>call VSCodeNotify("workbench.action.quickOpen")<CR>', { silent = true })

    -- Code operations
    vim.keymap.set('n', 'gd', '<Cmd>call VSCodeNotify("editor.action.revealDefinition")<CR>', { silent = true })
    vim.keymap.set('n', 'gr', '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>', { silent = true })
  end
end

return M
