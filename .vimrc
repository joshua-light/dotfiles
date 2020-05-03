" -------------
" -- Plugins --
" -------------
call plug#begin('~/.local/share/nvim/plugged')

" Common.
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Autocomplete.
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()


" -------------
" -- Configs --
" -------------
" Syntax highlighting is on.
syntax on

" When a new buffer is opened, the old one is hidden instead of being closed.
set hidden

" Lines are not wrapped.
set nowrap

" Swap files are created.
set swapfile

" All swap files are gathered in one place and are stored by full paths.
set directory=~/.vim/swap//

" Backup is enabled.
set backup

" All backup files are gathered in one place and are stored by full paths.
set backupdir=~/.vim/backup//

" For each change there is an undo file created to store the history of a file. 
set undofile

" All undo files are gathered in one place and are stored by full paths.
set undodir=~/.vim/undo//

" Searching with `/` highlights results as you type.
set incsearch

" Line numbers are visible.
set number

" Buffer for writing commands and echoing results is bigger.
set cmdheight=2

" Swap files are created, and `CursorHold` autocommand is called at a shorter
" interval of time.
set updatetime=50

" When auto-completion is used, short messages like "The only match"
" or "match 1 of 2" are not shown.
set shortmess+=c

" Cursor has always block shape.
set guicursor=n-v-c-i:block-cursor

" The column for syntax errors and other signs is always visible (not shifting
" the text).
set signcolumn=yes

" 24-bit RGB palette is used to display colors.
set termguicolors

" Sounds for errors are disabled.
set noerrorbells

" Screen flashing instead of sounds for errors is enabled (only to disable it
" later).
set visualbell

" Screen flashing is disabled at a terminal level.
set t_vb=

" Tab character is expanded to a number of space characters.
set expandtab

" Tab is equal to 4 spaces.
set tabstop=4

" The indentation level is equal to 4 spaces.
set shiftwidth=4

" Draws a line at 80 column.
set colorcolumn=80

" FZF.
fun! UseFZF()
    :nnoremap <C-p> :GFiles<CR>
endfun

" COC.
fun! UseCOC()
    " Closes the preview window after the completion is made.
    autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

    " Make <Tab> to complete the selected option.
    inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"

    " Make <CR> to complete the selected option.
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
endfun

:call UseFZF()
:call UseCOC()

" --------------
" -- Bindings --
" --------------
" Reload a current file.
:nnoremap <M-r> :source %<CR>

" Exit from whole VIM like in Emacs.
" (Not works without unbinding <C-c> first.)
:nnoremap <C-c> <Nop>
:nnoremap <C-x><C-c> :qa<CR>

" Use 0 as ^.
map 0 ^

" Splits.
nnoremap <M-w> :q<CR>
