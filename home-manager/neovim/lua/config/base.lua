--
vim.opt.autoread = true
vim.opt.termguicolors = true
vim.opt.compatible = false
vim.opt.backspace = 'indent,eol,start'
vim.opt.encoding = 'utf-8'
vim.opt.helplang = 'ja,en'

-- LazyVimのカスタムオプション設定
vim.g.lazyvim_version = "11.2"
vim.g.lazyvim_check_order = false -- インポート順序チェックを無効化

-- オプション設定
vim.opt.autowrite = true -- ファイルの自動保存を有効化
vim.opt.clipboard = "unnamedplus" -- システムクリップボードとの連携
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.conceallevel = 2 -- Markdownなどでの特殊文字の非表示
vim.opt.confirm = true -- 保存せずに終了する前に確認
vim.opt.cursorline = true -- カーソル行のハイライト
vim.opt.expandtab = true -- タブをスペースに変換
vim.opt.formatoptions = "jcroqlnt" -- テキスト整形オプション
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.ignorecase = true -- 検索時に大文字小文字を区別しない
vim.opt.inccommand = "nosplit" -- インクリメンタル置換のプレビュー
vim.opt.laststatus = 3 -- グローバルステータスライン
vim.opt.list = true -- 不可視文字を表示
vim.opt.listchars = { tab = '▸ ', trail = '·' }
vim.opt.mouse = "a" -- すべてのモードでマウスを使用可能
vim.opt.number = true -- 行番号を表示
vim.opt.relativenumber = true -- 相対行番号
vim.opt.scrolloff = 4 -- スクロール時に表示する余白の行数
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
vim.opt.shiftround = true -- インデントを丸める
vim.opt.shiftwidth = 2 -- インデントの幅
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.showmode = false -- モード表示を非表示
vim.opt.sidescrolloff = 8 -- 水平スクロール時に表示する余白の列数
vim.opt.signcolumn = "yes" -- 常に符号列を表示
vim.opt.smartcase = true -- ignorecase=trueの場合、大文字が含まれていれば大文字小文字を区別
vim.opt.smartindent = true -- スマートインデント
vim.opt.spelllang = { "en", "jp" }
vim.opt.splitbelow = true -- 水平分割は下に開く
vim.opt.splitkeep = "screen"
vim.opt.splitright = true -- 垂直分割は右に開く
vim.opt.tabstop = 2 -- タブの幅
vim.opt.softtabstop = 2
vim.opt.termguicolors = true -- 24ビットカラーサポート
vim.opt.timeoutlen = 300 -- キーコードの待機時間
vim.opt.undofile = true -- 永続的なundo履歴
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- スワップファイルを書き込む間隔
vim.opt.wildmode = "longest:full,full" -- コマンドライン補完
vim.opt.winminwidth = 5 -- 最小ウィンドウ幅
vim.opt.wrap = false -- テキストの折り返しなし
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.laststatus = 2
vim.opt.autoindent = true
vim.opt.showcmd = true
vim.opt.background = 'dark'
vim.opt.wildmenu = true
vim.opt.ruler = true
vim.opt.showmatch = true
vim.opt.cursorcolumn = true

-- fillcharsの設定を修正
-- 1文字だけ使用するように設定を修正
vim.opt.fillchars = {
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- Neovim 0.10以上の場合は追加設定を行う
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.fillchars:append({
    foldopen = "▾",
    foldclose = "▸",
  })
end 

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

-- transparency settings
vim.opt.winblend = 20
vim.opt.pumblend = 20

-- Neovim GUI
if vim.g.neovide then
  vim.g.neovide_transparency = 0.8        -- 0.0-1.0
  vim.g.transparency = 0.8                -- 0.0-1.0
  vim.g.neovide_background_color = '#0f1117' .. string.format('%x', math.floor(255 * 0.8))
end

-- FloatWindo
vim.opt.wildoptions = 'pum'
vim.opt.wildmode = 'longest:full'
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = function()
    vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'PmenuSel', { bg = '#373844' })
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
    vim.api.nvim_set_hl(0, "NonText", { bg = "NONE", ctermbg = "NONE" })
    vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE", ctermbg = "NONE" })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE", ctermbg = "NONE" })
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", ctermbg = "NONE" })
  end,
})
