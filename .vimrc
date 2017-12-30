if 0 | endif

if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.vim/bundle/neobundle.vim/

" Required:
call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" My Bundles here:
" Refer to |:NeoBundle-examples|.
" Note: You don't set neobundle setting in .gvimrc!
NeoBundle 'tomasr/molokai'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neomru.vim'
call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck
colorscheme molokai

" SET 
set fenc=utf-8
set nobackup
set noswapfile
" "
set autoread
" "
set hidden
set showcmd
set number
set cursorline
set cursorcolumn
" "
set virtualedit=onemore
set smartindent
set showmatch
set laststatus=2
set wildmode=list:longest
" "
nnoremap j gj
nnoremap k gk

set expandtab
" "
set tabstop=2
set shiftwidth=2

" "
set ignorecase
" "
set smartcase
" "
set incsearch
set wrapscan
set hlsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>
