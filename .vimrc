if 0 | endif
filetype off
filetype plugin indent off

" dein {{{

  if &compatible
    set nocompatible
  endif

  " Required:
  set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

  " Required:
   call dein#begin(expand('~/.vim/dein'))

  " Required:
  call dein#add('Shougo/dein.vim')
  call dein#add('Shougo/vimproc.vim', {'build': 'make'})

  call dein#add('Shougo/neocomplete.vim')
  call dein#add('Shougo/neomru.vim')
  call dein#add('tomasr/molokai')
  call dein#add('Shougo/unite.vim')
  call dein#add('Shougo/neomru.vim')
  call dein#add('editorconfig/editorconfig-vim')
  call dein#add('Townk/vim-autoclose')
  call dein#add('scrooloose/nerdtree')
  call dein#add('bronson/vim-trailing-whitespace')

  call dein#end()

  " Required:
  filetype plugin indent on

  if dein#check_install()
    call dein#install()
  endif

" }}}



" SET {{{

  set fenc=utf-8
  set nobackup
  set noswapfile
  set autoread
  set hidden
  set showcmd
  set number
  set cursorline
  set cursorcolumn
  set virtualedit=onemore
  set smartindent
  set showmatch
  set laststatus=2
  set wildmode=list:longest

  nnoremap j gj
  nnoremap k gk
  nnoremap : ;
  nnoremap ; :

  set expandtab
  set tabstop=2
  set shiftwidth=2
  set ignorecase
  set smartcase
  set incsearch
  set wrapscan
  set hlsearch
  nmap <Esc><Esc> :nohlsearch<CR><Esc>
  set visualbell t_vb=
  let OSTYPE = system('uname')
  if OSTYPE == "Darwin\n"
    :set term=xterm-256color
    :syntax on
  endif

" }}}

" unite.vim SETTING {{{

  " start with insert mode
  let g:unite_enable_start_insert=1
  " list of file in current directory
  noremap <C-P> :Unite -buffer-name=file file<CR>
  " list of file recently used
  noremap <C-Z> :Unite file_mru<CR>
  " set 'sources' to the directory of the editing file
  noremap :uff :<C-u>UniteWithBufferDir file -buffer-name=file<CR>
  " split window
  au FileType unite nnoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
  au FileType unite inoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
  " split window vertically
  au FileType unite nnoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
  au FileType unite inoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
  " exit to esc twice
  au FileType unite nnoremap <silent> <buffer> <ESC><ESC> :q<CR>
  au FileType unite inoremap <silent> <buffer> <ESC><ESC> <ESC>:q<CR>

" }}}

" NERDTree SETTING {{{

  autocmd vimenter * if !argc() | NERDTree | endif
  autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" }}}

" Change color of the status line when entering to insert mode {{{

  let g:hi_insert = 'highlight StatusLine guifg=darkblue guibg=darkyellow gui=none ctermfg=blue ctermbg=yellow cterm=none'

  if has('syntax')
    augroup InsertHook
      autocmd!
      autocmd InsertEnter * call s:StatusLine('Enter')
      autocmd InsertLeave * call s:StatusLine('Leave')
    augroup END
  endif

  let s:slhlcmd = ''
  function! s:StatusLine(mode)
    if a:mode == 'Enter'
      silent! let s:slhlcmd = 'highlight ' . s:GetHighlight('StatusLine')
      silent exec g:hi_insert
    else
      highlight clear StatusLine
      silent exec s:slhlcmd
    endif
  endfunction

  function! s:GetHighlight(hi)
    redir => hl
    exec 'highlight '.a:hi
    redir END
    let hl = substitute(hl, '[\r\n]', '', 'g')
    let hl = substitute(hl, 'xxx', '', '')
    return hl
  endfunction

" }}}

filetype on
