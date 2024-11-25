--
vim.opt.autoread = true
vim.opt.termguicolors = true
vim.opt.compatible = false
vim.opt.backspace = 'indent,eol,start'
vim.opt.encoding = 'utf-8'
vim.opt.helplang = 'ja,en'
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.laststatus = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.showcmd = true
vim.opt.background = 'dark'
vim.opt.wildmenu = true
vim.opt.ruler = true
vim.opt.showmatch = true
vim.opt.clipboard:append('unnamed')
vim.opt.updatetime = 500
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', trail = '·' }

-- highlighter
vim.cmd('highlight SpecialKey ctermbg=235 guibg=#2c2d27')
vim.cmd('highlight ColorColumn ctermbg=235 guibg=#2c2d27')
vim.cmd('syntax on')
vim.cmd('filetype plugin indent on')

-- status bar
vim.g.airline_theme = 'luna'
vim.g.airline_extensions_tabline_enabled = 1

-- key map
vim.api.nvim_set_keymap('i', 'jj', '<Esc><Esc><Esc>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-j>', '<Down>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-k>', '<Up>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-h>', '<Left>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-l>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('i', '<C-f>', '<Delete>', { noremap = true })
vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', ':', ';', { noremap = true })
vim.api.nvim_set_keymap('n', ';', ':', { noremap = true })

local mapleader = " "
vim.g.mapleader = mapleader
vim.api.nvim_set_keymap('n', '<Leader>', '<Nop>', {})
vim.api.nvim_set_keymap('x', '<Leader>', '<Nop>', {})
vim.api.nvim_set_keymap('n', '<Plug>(lsp)', '<Nop>', {})
vim.api.nvim_set_keymap('x', '<Plug>(lsp)', '<Nop>', {})
vim.api.nvim_set_keymap('n', 'm', '<Plug>(lsp)', {})
vim.api.nvim_set_keymap('x', 'm', '<Plug>(lsp)', {})
vim.api.nvim_set_keymap('n', '<Plug>(ff)', '<Nop>', {})
vim.api.nvim_set_keymap('x', '<Plug>(ff)', '<Nop>', {})
vim.api.nvim_set_keymap('n', 'n', '<Plug>(ff)', {})
vim.api.nvim_set_keymap('x', 'n', '<Plug>(ff)', {})

-- terminal
if vim.fn.has('nvim') then
  vim.cmd('command! -nargs=* T split | wincmd j | resize 20 | terminal <args>')
  vim.cmd('autocmd TermOpen * startinsert')
end
