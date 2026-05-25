" .vimrc — minimal config for QNAP vim
" Place in /share/NFSv=4/homes/admin/.vimrc

set nocompatible
syntax on
set number
set ruler
set hlsearch
set incsearch
set ignorecase
set smartcase
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set backspace=indent,eol,start
set laststatus=2
set encoding=utf-8
set fileencoding=utf-8

" Highlight trailing whitespace
highlight TrailingWS ctermbg=red guibg=red
match TrailingWS /\s\+$/
