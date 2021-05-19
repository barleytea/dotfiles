if g:dein#_cache_version !=# 150 || g:dein#_init_runtimepath !=# '/Users/miyoshi_s/.vim,/usr/share/vim/vimfiles,/usr/share/vim/vim81,/usr/share/vim/vimfiles/after,/Users/miyoshi_s/.vim/after,/Users/miyoshi_s/.vim/dein/repos/github.com/Shougo/dein.vim' | throw 'Cache loading error' | endif
let [plugins, ftplugin] = dein#load_cache_raw(['/Users/miyoshi_s/.vimrc'])
if empty(plugins) | throw 'Cache loading error' | endif
let g:dein#_plugins = plugins
let g:dein#_ftplugin = ftplugin
let g:dein#_base_path = '/Users/miyoshi_s/.vim/dein'
let g:dein#_runtime_path = '/Users/miyoshi_s/.vim/dein/.cache/.vimrc/.dein'
let g:dein#_cache_path = '/Users/miyoshi_s/.vim/dein/.cache/.vimrc'
let &runtimepath = '/Users/miyoshi_s/.vim,/usr/share/vim/vimfiles,/Users/miyoshi_s/.vim/dein/repos/github.com/Shougo/vimproc.vim,/Users/miyoshi_s/.vim/dein/repos/github.com/Shougo/dein.vim,/Users/miyoshi_s/.vim/dein/.cache/.vimrc/.dein,/usr/share/vim/vim81,/Users/miyoshi_s/.vim/dein/.cache/.vimrc/.dein/after,/usr/share/vim/vimfiles/after,/Users/miyoshi_s/.vim/after'
