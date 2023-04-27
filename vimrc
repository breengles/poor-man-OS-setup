let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Install vim-plug to use plugins
call plug#begin('~/.vim/plugged')
	" NERDTree is used to navigate in project
	" Comes with fancy plugins
	Plug 'preservim/nerdtree' |
            \ Plug 'Xuyuanp/nerdtree-git-plugin'
	Plug 'ryanoasis/vim-devicons'

	" Autocompletion and refactor with jedi
	Plug 'davidhalter/jedi-vim'

	" ALE is used in refactoring too
	Plug 'dense-analysis/ale'
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


syntax on
filetype plugin indent on
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

