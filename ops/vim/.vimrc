set nocompatible

" Load plugins using vundle
" ---------------------------
filetype off
filetype plugin indent on
source ~/.vim/plugins.vim

" Load initialization files
" ---------------------------
runtime! init/**.vim
source ~/.vim/mappings.vim

" Load machine-local settings
" ---------------------------
silent! source ~/.vimrc.local
