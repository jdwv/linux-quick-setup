".vimrc
filetype on " Enable filetype detection
filetype plugin indent on
syntax on

" Auto reload .vimrc when saved
au BufWritePost .vimrc so ~/.vimrc

# User paste mode for inserts - keeps indentation
# Set as shortcut - don't enable by default
:map <F10> :set invpaste<CR>

set backspace=2
set nocompatible " Using Vim, not Vi
set backspace=indent,eol,start " Normal backspace behaviour
set number
set showtabline=2

" Indentation
set autoindent " Copy indent from previous line
set cindent
set cinkeys=0{,0},:,0#,!^F,0"
"set smartindent

" Tabs instead of spaces
set tabstop=4
set shiftwidth=4
set expandtab


"VIM Theme
"Note background set to dark in .vimrc
" ctermfg/ctermbg for console
" guifg/guibg for gui
highlight Normal     guifg=gray guibg=black
highlight Comment    ctermfg=red

" Remove toolbar
set guioptions-=T

" Command Tab Complete
set wildmode=longest,list,full
set wildmenu

set cursorline
"
" " show the matching part of the pair for [] {} and ()
set showmatch

" enable all Python syntax highlighting features
let python_highlight_all = 1
