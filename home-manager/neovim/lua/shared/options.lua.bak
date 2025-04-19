-- Settings file generated from VSCode sync
-- Warning: This file is auto-generated. Take backup before manual editing.

local M = {}

function M.setup()
  -- Basic settings
  vim.opt.number = true          -- Show line numbers
  vim.opt.relativenumber = true  -- Show relative line numbers
  vim.opt.cursorline = true      -- Highlight cursor line
  vim.opt.cursorcolumn = true    -- Highlight cursor column
  vim.opt.wrap = false           -- No line wrapping
  vim.opt.tabstop = 2            -- Tab width
  vim.opt.shiftwidth = 2         -- Indent width
  vim.opt.expandtab = true       -- Expand tabs to spaces
  vim.opt.smartindent = true     -- Smart indentation
  vim.opt.autoindent = true      -- Auto indentation

  -- Search settings
  vim.opt.hlsearch = true        -- Highlight search results
  vim.opt.ignorecase = true      -- Case-insensitive search
  vim.opt.smartcase = true       -- Smart case search

  -- System settings
  vim.opt.backup = false         -- No backup files
  vim.opt.writebackup = false    -- No backup files during write
  vim.opt.swapfile = false       -- No swap files
  vim.opt.updatetime = 50        -- Update time
  vim.opt.clipboard = "unnamedplus" -- Use system clipboard

  -- VSCode mode specific settings
  if vim.g.vscode then
    -- Override some settings in VSCode
    vim.opt.hlsearch = false     -- Let VSCode handle highlighting
    vim.opt.cursorline = false   -- Let VSCode handle cursor line
    vim.opt.cursorcolumn = false -- Let VSCode handle cursor column
  end
end

return M
