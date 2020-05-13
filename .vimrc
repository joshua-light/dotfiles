" -------------
" -- Plugins --
" -------------
call plug#begin('~/.local/share/nvim/plugged')

" -- Visual --
" Atom One Dark theme.
Plug 'joshdick/onedark.vim'

" -- Common --
" Git.
Plug 'tpope/vim-fugitive'

" Icons are shown in many plugins.
Plug 'ryanoasis/vim-devicons'

" More flexible search motions.
Plug 'easymotion/vim-easymotion'

" Highlights after incremental search are turned off automatically.
Plug 'haya14busa/is.vim'

" Incredible fast fuzzy search.
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" Filesystem tree.
Plug 'scrooloose/nerdtree'

" Autocompletion.
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" .editorconfig.
Plug 'editorconfig/editorconfig-vim'

" Syntax checking.
Plug 'w0rp/ale'

" Start screen is more customizable.
Plug 'mhinz/vim-startify'

" -- Languages --

" Latex.
Plug 'xuhdev/vim-latex-live-preview', { 'for': 'tex' }

" Python.
" Syntax highlighting.
Plug 'vim-python/python-syntax'

" C#.
Plug 'OmniSharp/omnisharp-vim'
Plug 'OrangeT/vim-csharp'

call plug#end()


" -------------
" -- Configs --
" -------------
" Encoding is UTF-8.
set encoding=utf-8

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

" Messages are not shown at last line when in Insert, Visual or Replace modes.
set noshowmode

" Current line is highlighted.
set cursorline

" Colors.
fun InitColors()
    " Syntax highlighting is on.
    syntax on

    " Color scheme is OneDark.
    colorscheme onedark

    " 24-bit RGB palette is used to display colors.
    set termguicolors

    " Colors are customized.
    hi ColorColumn guifg=#5c6370
    hi StatusLine guibg=#212429
    hi CursorLine guibg=#23272c
endfun

:call InitColors()


" -- Plugins --
" EasyMotion.
fun InitEasyMotion()
    map s <Plug>(easymotion-overwin-f2)
endfun

:call InitEasyMotion()

" FZF.
fun InitFZF()
    fun! RipgrepFzf(query, fullscreen)
        let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
        let initial_command = printf(command_fmt, shellescape(a:query))
        let reload_command = printf(command_fmt, '{q}')
        let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
        call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
    endfun

    " An interactive fuzzy search with RG command.
    command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

    :nnoremap <M-p> <Nop>
    :nnoremap <M-p> :GFiles<CR>

    :nnoremap <M-x> <Nop>
    :nnoremap <M-x> :Commands<CR>

    " Completion is done in floating window at the center of the screen.
    let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8, 'yoffset':0.5, 'xoffset': 0.5, 'highlight': 'Todo', 'border': 'sharp' } }
endfun

:call InitFZF()

" NERDTree.
fun InitNERDTree() 
    :nnoremap <M-1> :NERDTreeToggle<CR>
endfun

:call InitNERDTree()

" COC.
fun InitCOC()
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
fun InitAle()
    let g:ale_lint_on_enter = 0
    let g:ale_lint_on_save = 0
    let g:ale_lint_delay = 50
    let g:ale_lint_on_text_changed = 'always'

    let g:ale_linters = { 'cs': ['OmniSharp'] }
endfun

:call InitAle()

" -- Languages --
fun InitPython()
    let g:python_highlight_all = 1
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

fun InitCSharp()
    " stdio Roslyn server is used (instead of HTTP).
    let g:OmniSharp_server_stdio = 1

    " Semantic highlighting is turned on.
    let g:OmniSharp_highlight_types = 3

    " Mono is used as CSharp backend.
    let g:OmniSharp_server_use_mono = 1

    " Show type information automatically when the cursor stops moving.
    " Note that the type is echoed to the Vim command line, and will overwrite
    " any other messages in this space including e.g. ALE linting messages.
    autocmd CursorHold *.cs OmniSharpTypeLookup

    " The following commands are contextual, based on the cursor position.
    autocmd FileType cs nnoremap <buffer> gd :OmniSharpGotoDefinition<CR>
endfun

:call InitCSharp()


" --------------
" -- Bindings --
" --------------
" Reload a current file.
:nnoremap <A-r> :source %<CR>

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
nnoremap <A-w> :q<CR>

" Run previous shell command.
nnoremap <A-;> :!!<CR>

" Git.
nnoremap <A-g> :Gstatus<CR>
nnoremap <C-k> :Gcommit<CR>
nmap <C-p> <Nop>
nnoremap <C-p> :Gpush<CR>
