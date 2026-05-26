" .vimrc — QNAP-kompatibel (busybox vi + QNAP-vim 7.2 + Entware-vim)
" Getrackt in: qnap-dotfiles/.vimrc
" Deploy: /root/.vimrc  und  /share/NFSv=4/homes/admin/.vimrc
"
" QNAP hat zwei vim-Varianten:
"   /bin/vim  -> QNAP-QPKG-vim 7.2 (2008), sucht Syntax unter /usr/local/share/vim/
"                → hat KEINE syntax-files → E484-Fehler ohne Guard
"   /opt/bin/vim -> Entware-vim (aktuell), Syntax unter /opt/share/vim/
"                → voll funktionsfähig
"
" Dieser Guard verhindert E484 beim QNAP-System-vim:

set nocompatible

" Syntax nur aktivieren wenn Syntax-Support vorhanden (verhindert E484 auf QNAP-vim 7.2)
if has('syntax') && (isdirectory('/opt/share/vim') || isdirectory('/usr/local/share/vim') || isdirectory('/usr/share/vim'))
  syntax on
endif

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

" Encoding nur setzen wenn supported (Entware-vim ja, QNAP-vim 7.2 teilweise)
if has('multi_byte')
  set encoding=utf-8
  set fileencoding=utf-8
endif

" Trailing Whitespace highlighten (nur mit Syntax-Support)
if has('syntax') && (isdirectory('/opt/share/vim') || isdirectory('/usr/local/share/vim') || isdirectory('/usr/share/vim'))
  highlight TrailingWS ctermbg=red guibg=red
  match TrailingWS /\s\+$/
endif
