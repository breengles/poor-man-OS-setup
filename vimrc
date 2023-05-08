let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Install vim-plug to use plugins
call plug#begin()
  " NERDTree is used to navigate in project
  " Comes with fancy plugins
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'

  Plug 'dunstontc/vim-vscode-theme'

  Plug 'dhruvasagar/vim-table-mode'

  " Autocompletion and refactor with jedi
  Plug 'davidhalter/jedi-vim'

  " ALE is used in refactoring too
  Plug 'dense-analysis/ale'

  Plug 'tpope/vim-fugitive'

  Plug 'ryanoasis/vim-devicons'
call plug#end()




" I love linters
" I would even say it's not enough linters T_T
let g:ale_linters = {
      \   'python': ['flake8', 'pylint', 'pycodestyle', 'pydocstyle', 'mypy', 'bandit', 'pyls'],
      \}

" I'm still not sure if it works, but I'm not satisfied with my autoimports
" yet.
let g:ale_completion_autoimport = 1

" How to fix code with :ALEFix
let g:ale_fixers = [
  \   'autoimport',
  \   'remove_trailing_lines',
  \   'isort',
  \   'ale#fixers#generic_python#BreakUpLongLines',
  \   'yapf',
  \]

if (has("termguicolors"))
 set termguicolors
endif

syntax on
filetype plugin indent on

colorscheme dark_plus

set modelines=0
set number
set ttyfast
set formatoptions=tcqrn1
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set noshiftround
set scrolloff=5
set backspace=indent,eol,start
set hlsearch
set incsearch
set ignorecase
set smartcase
set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.
set laststatus=2
set showmode
set showcmd
set matchpairs+=<:>
set expandtab
set mouse=a
set clipboard+=unnamedplus

let NERDTreeShowHidden=1

let g:python3_host_prog = '~/mambaforge/bin/python'
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0

let mapleader = ' '

" Start NERDTree and put the cursor back in the other window.
autocmd VimEnter * NERDTree | wincmd p

" Start NERDTree when Vim starts with a directory argument.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists('s:std_in') |
  \ execute 'NERDTree' argv()[0] | wincmd p | enew | execute 'cd '.argv()[0] | endif

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

function! s:isAtStartOfLine(mapping)
    let text_before_cursor = getline('.')[0 : col('.')-1]
    let mapping_pattern = '\V' . escape(a:mapping, '\')
    let comment_pattern = '\V' . escape(substitute(&l:commentstring, '%s.*$', '', ''), '\')
    return (text_before_cursor =~? '^' . ('\v(' . comment_pattern . '\v)?') . '\s*\v' . mapping_pattern . '\v$')
endfunction
  
inoreabbrev <expr> <bar><bar>
        \ <SID>isAtStartOfLine('\|\|') ?
        \ '<c-o>:TableModeEnable<cr><bar><space><bar><left><left>' : '<bar><bar>'
inoreabbrev <expr> __
        \ <SID>isAtStartOfLine('__') ?
        \ '<c-o>:silent! TableModeDisable<cr>' : '__'

