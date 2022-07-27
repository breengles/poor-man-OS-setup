set nocompatible

filetype off

syntax on

filetype plugin indent on

set modelines=0

set wrap
nnoremap <F2> :set invpaste paste?<CR>
imap <F2> <C-O>:set invpaste paste?<CR>
set pastetoggle=<F2>

set formatoptions=tcqrn1
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set noshiftround

set scrolloff=5
set backspace=indent,eol,start

set ttyfast

set laststatus=2

set showmode
set showcmd

set matchpairs+=<:>

set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:.

set number

set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ [BUFFER=%n]\ %{strftime('%c')}

set encoding=utf-8

set hlsearch
set incsearch
set ignorecase
set smartcase

set viminfo='100,<9999,s100

nnoremap <silent> <Space> @=(foldlevel('.')?'za':"\<Space>")<CR>
vnoremap <Space> zf

autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview"
