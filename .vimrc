""""""""""""""""""""""""""""""
" vimrc
""""""""""""""""""""""""""""""
call plug#begin('~/.vim/plugged')

" Japanese Help
Plug 'vim-jp/vimdoc-ja'

" Customize status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Color theme
Plug 'dracula/vim', { 'as': 'dracula' }

call plug#end()
""""""""""""""""""""""""""""""
set nocompatible
set backspace=indent,eol,start
set encoding=utf-8
set helplang=ja,en
set number
set expandtab
set hlsearch
set ignorecase
set incsearch
set smartcase
set laststatus=2
syntax on
set autoindent
filetype plugin indent on
set showcmd
set background=dark
set wildmenu
set ruler
set showmatch
set clipboard+=unnamed

" line number color
highlight lineNr term=underline ctermfg=11 guifg=Grey

" setting status bar
let g:airline_theme='luna'

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
