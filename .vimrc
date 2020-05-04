" -------------
" -- Plugins --
" -------------
call plug#begin('~/.local/share/nvim/plugged')

" -- Visual --
Plug 'joshdick/onedark.vim'

" -- Common --
" Brackets of different levels have different colors.
Plug 'frazrepo/vim-rainbow'

" Icons are shown in many plugins.
Plug 'ryanoasis/vim-devicons'

" Incredible fast fuzzy search.
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Filesystem tree.
Plug 'scrooloose/nerdtree'

" Autocompletion.
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Syntax checking.
Plug 'w0rp/ale'

" -- Languages --
"
" Python.

call plug#end()


" -------------
" -- Configs --
" -------------
" Encoding is UTF-8.
set encoding=utf-8

" Syntax highlighting is on.
syntax on

" Color scheme is OneDark.
colorscheme onedark

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

" Searching with `/` is case insensitive.
set ignorecase

" Searching with `/` is case insensitive only if there are no capital letters
" in search.
set smartcase

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

" Colors from dark palette are used (doesn't actually change the background
" color).
set background=dark

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
highlight ColorColumn ctermbg=0 guibg=#000000

" Messages are not shown at last line when in Insert, Visual or Replace modes.
set noshowmode

" -- Plugins --
" vim-rinbow.
fun! InitVimRainbow()
    let g:rainbow_active = 1
endfun

:call InitVimRainbow()

" FZF.
fun! InitFZF()
    :nnoremap <M-p> <Nop>
    :nnoremap <M-p> :GFiles<CR>

    :nnoremap <M-x> <Nop>
    :nnoremap <M-x> :Commands<CR>
endfun

:call InitFZF()

" NERDTree.
fun! InitNERDTree() 
    :nnoremap <M-1> :NERDTreeToggle<CR>
endfun

:call InitNERDTree()

" COC.
fun! InitCOC()
    " Closes the preview window after the completion is made.
    autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

    " Make <Tab> to complete the selected option.
    inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"

    " Make <CR> to complete the selected option.
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"

    " Navigation.
    nmap gd <Nop>
    nmap gd <Plug>(coc-definition)

    nmap gr <Nop>
    nmap gr <Plug>(coc-references)

    nmap ` <Nop>
    nmap ` <Plug>(coc-rename)
endfun

:call InitCOC()

" Ale.
fun! InitAle()
    let g:ale_lint_on_enter = 0
    let g:ale_lint_on_save = 0
    let g:ale_lint_delay = 50
    let g:ale_lint_on_text_changed = 'always'
endfun

:call InitAle()

" -- Languages --
fun InitPython()
    let python_highlight_all=1
    let NERDTreeIgnore=['\.pyc$', '\~$']

    au BufNewFile,BufRead *.py
      \   set tabstop=4
      \ | set softtabstop=4
      \ | set shiftwidth=4
      \ | set textwidth=79
      \ | set expandtab
      \ | set autoindent
      \ | set fileformat=unix
endfun

:call InitPython()


" --------------
" -- Bindings --
" --------------
" Reload a current file.
:nnoremap <M-r> :source %<CR>

" Exit from whole VIM like in Emacs.
" (Not works without unbinding <C-c> first.)
:nnoremap <C-c> <Nop>
:nnoremap <C-x><C-c> :qa!<CR>

" Use 0 as ^.
map 0 ^

" Use jj to escape Insert mode.
imap jj <Esc>

" Make sure <C-c> behaves as <Esc> (it helps with autoclosing windows).
imap <C-c> <Esc>

" Splits.
nnoremap <M-w> :q<CR>
