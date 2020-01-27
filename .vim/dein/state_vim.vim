if g:dein#_cache_version !=# 150 || g:dein#_init_runtimepath !=# '/home/miyoshi-s/.vim,/var/lib/vim/addons,/usr/share/vim/vimfiles,/usr/share/vim/vim80,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,/home/miyoshi-s/.vim/after,/home/miyoshi-s/.cache/dein/repos/github.com/Shougo/dein.vim' | throw 'Cache loading error' | endif
let [plugins, ftplugin] = dein#load_cache_raw(['/home/miyoshi-s/.vimrc'])
if empty(plugins) | throw 'Cache loading error' | endif
let g:dein#_plugins = plugins
let g:dein#_ftplugin = ftplugin
let g:dein#_base_path = '/home/miyoshi-s/.vim/dein'
let g:dein#_runtime_path = '/home/miyoshi-s/.vim/dein/.cache/.vimrc/.dein'
let g:dein#_cache_path = '/home/miyoshi-s/.vim/dein/.cache/.vimrc'
let &runtimepath = '/home/miyoshi-s/.vim,/var/lib/vim/addons,/usr/share/vim/vimfiles,/home/miyoshi-s/.vim/dein/.cache/.vimrc/.dein,/usr/share/vim/vim80,/home/miyoshi-s/.vim/dein/.cache/.vimrc/.dein/after,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,/home/miyoshi-s/.vim/after,/home/miyoshi-s/.cache/dein/repos/github.com/Shougo/dein.vim'
