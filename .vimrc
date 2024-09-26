call plug#begin('~/.vim/plugged')

Plug 'vim-jp/vimdoc-ja'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/fern-git-status.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
Plug 'lambdalisue/glyph-palette.vim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'junegunn/fzf', {'dir': '~/.fzf_bin', 'do': { -> fzf#install() }}
Plug 'junegunn/fzf.vim'
Plug 'yuki-yano/fzf-preview.vim', {'branch': 'release/rpc' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'rust-lang/rust.vim'
Plug 'lambdalisue/fern-hijack.vim'
Plug 'itmammoth/doorboy.vim'
Plug 'github/copilot.vim'

call plug#end()

" set options
set autoread
set termguicolors
set nocompatible
set backspace=indent,eol,start
set encoding=utf-8
set helplang=ja,en
set number
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set hlsearch
set ignorecase
set incsearch
set smartcase
set laststatus=2
set autoindent
set smartindent
set showcmd
set background=dark
set wildmenu
set ruler
set showmatch
set clipboard+=unnamed
set updatetime=500
set cursorline "現在の行を強調表示
set cursorcolumn "現在の列を強調表示
"タブと行末のスペースをハイライトする
set list
set listchars=tab:\ \ ,trail:\
highlight SpecialKey ctermbg=235 guibg=#2c2d27
highlight ColorColumn ctermbg=235 guibg=#2c2d27

syntax on
filetype plugin indent on

" line number color
highlight lineNr term=underline ctermfg=11 guifg=Grey

" setting status bar
let g:airline_theme='luna'
let g:airline#extentions#tabline#enabled = 1

" setting key maps
inoremap jj <Esc><Esc><Esc>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-h> <Left>
inoremap <C-l> <Right>
inoremap <C-f> <Delete>
nnoremap j gj
nnoremap k gk
nnoremap : ;
nnoremap ; :

let g:mapleader = "\<Space>"
nnoremap <Leader>    <Nop>
xnoremap <Leader>    <Nop>
nnoremap <Plug>(lsp) <Nop>
xnoremap <Plug>(lsp) <Nop>
nmap     m           <Plug>(lsp)
xmap     m           <Plug>(lsp)
nnoremap <Plug>(ff)  <Nop>
xnoremap <Plug>(ff)  <Nop>
nmap     n           <Plug>(ff)
xmap     n           <Plug>(ff)

"" fern.vim
let g:fern#renderer = 'nerdfont'
nnoremap <silent> <Leader>e <Cmd>Fern . -drawer<CR>
nnoremap <silent> <Leader>E <Cmd>Fern . -drawer -reveal=%<CR>

"" coc.nvim
let g:coc_global_extensions = ['coc-tsserver', 'coc-eslint', 'coc-prettier', 'coc-git', 'coc-fzf-preview', 'coc-lists', 'coc-flutter']

inoremap <silent> <expr> <C-Space> coc#refresh()

nnoremap <silent> K             <Cmd>call <SID>show_documentation()<CR>
nmap     <silent> <Plug>(lsp)rn <Plug>(coc-rename)
nmap     <silent> <Plug>(lsp)a  <Plug>(coc-codeaction-cursor)

function! s:coc_typescript_settings() abort
  nnoremap <silent> <buffer> <Plug>(lsp)f :<C-u>CocCommand eslint.executeAutofix<CR>:CocCommand prettier.formatFile<CR>
endfunction

augroup coc_ts
  autocmd!
  autocmd FileType typescript,typescriptreact call <SID>coc_typescript_settings()
augroup END

function! s:show_documentation() abort
  if index(['vim','help'], &filetype) >= 0
    execute 'h ' . expand('<cword>')
  elseif coc#rpc#ready()
    call CocActionAsync('doHover')
  endif
endfunction

"" fzf-preview
let $BAT_THEME                     = 'dracula'
let $FZF_PREVIEW_PREVIEW_BAT_THEME = 'dracula'

nnoremap <silent> <Plug>(ff)r  <Cmd>CocCommand fzf-preview.ProjectFiles<CR>
nnoremap <silent> <Plug>(ff)s  <Cmd>CocCommand fzf-preview.GitStatus<CR>
nnoremap <silent> <Plug>(ff)gg <Cmd>CocCommand fzf-preview.GitActions<CR>
nnoremap <silent> <Plug>(ff)b  <Cmd>CocCommand fzf-preview.Buffers<CR>
nnoremap          <Plug>(ff)f  :<C-u>CocCommand fzf-preview.ProjectGrep --add-fzf-arg=--exact --add-fzf-arg=--no-sort<Space>

nnoremap <silent> <Plug>(lsp)q  <Cmd>CocCommand fzf-preview.CocCurrentDiagnostics<CR>
nnoremap <silent> <Plug>(lsp)rf <Cmd>CocCommand fzf-preview.CocReferences<CR>
nnoremap <silent> <Plug>(lsp)d  <Cmd>CocCommand fzf-preview.CocDefinition<CR>
nnoremap <silent> <Plug>(lsp)t  <Cmd>CocCommand fzf-preview.CocTypeDefinition<CR>
nnoremap <silent> <Plug>(lsp)o  <Cmd>CocCommand fzf-preview.CocOutline --add-fzf-arg=--exact --add-fzf-arg=--no-sort<CR>

"" treesitter
if has('nvim')
lua <<EOF
require('nvim-treesitter.configs').setup {
    ensure_installed = {
        "bash",
        "fish",
        "go",
        "java",
        "javascript",
        "lua",
        "rust",
        "tsx",
        "typescript",
        "vim",
        "yaml"
    },
    highlight = {
        enable = true,
    },
}
EOF
endif

"" terminal
if has('nvim')
command! -nargs=* T split | wincmd j | resize 20 | terminal <args>
autocmd TermOpen * startinsert
endif

"" rust-lang
let g:rustfmt_autosave = 1

