"        _
" __   _(_)_ __ ___  _ __ ___
" \ \ / / | '_ ` _ \| '__/ __|
"  \ V /| | | | | | | | | (__
"   \_/ |_|_| |_| |_|_|  \___|

let mapleader ="-"

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-commentary'
Plug 'vim-airline/vim-airline'
Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround'
Plug 'morhetz/gruvbox'
Plug 'ekalinin/Dockerfile.vim'
Plug 'previm/previm'
call plug#end()

" Some basics:
	set nocompatible
	filetype plugin on
	syntax on
	set encoding=utf-8
	set number
	set hlsearch
	set incsearch
	set ignorecase " case insensitivity when searching
	set smartcase  " reenables case sensitivity when pattern has upper case
	set cursorline
	set noesckeys
	set autoindent
	set pastetoggle=<F3> " F3 toggles paste/nopaste
	set autochdir
	" set relativenumber
	set background=dark
	let g:gruvbox_contrast_dark = 'hard'
	colorscheme gruvbox
	let NERDTreeShowHidden=1 " show hidden .dotfiles in nerdtree

" Previm open command
	let g:previm_open_cmd = 'google-chrome --new-window'

" remap ESC to jk because my pinky is fucked
	inoremap jk <ESC>

" keep search results at the center of the screen
	nnoremap n nzz
	nnoremap N Nzz

" Press <leader> Enter to remove search highlights
	noremap <silent> <leader><cr> :noh<cr>

" Press <leader> r to resource ~/.vimrc
	noremap <leader>r :source ~/.vimrc<cr>

" set comment string for vhdl files
	autocmd FileType vhdl setlocal commentstring=--\ %s

" Interpret _defconfig files as conf
	autocmd BufNewFile,BufRead *_defconfig,*.defconfig set syntax=conf

" set comment string for conf files
	autocmd FileType conf setlocal commentstring=#\ %s

" Splits open at the bottom and right, which is non-retarded, unlike vim defaults.
	set splitbelow
	set splitright

" Shortcutting split navigation, saving a keypress:
	map <C-h> <C-w>h
	map <C-j> <C-w>j
	map <C-k> <C-w>k
	map <C-l> <C-w>l

" resize current buffer by +/- 5
        nnoremap <C-left> :vertical resize -5<cr>
        nnoremap <C-down> :resize +5<cr>
        nnoremap <C-up> :resize -5<cr>
        nnoremap <C-right> :vertical resize +5<cr>

" .tex files automatically detected
	autocmd BufRead,BufNewFile *.tex set filetype=tex

" Readmes autowrap text:
	autocmd BufRead,BufNewFile README.* set tw=79

" Get line, word and character counts:
	map <leader>w :!wc %<CR>

" Spell-check:
	map <leader>s :setlocal spell! spelllang=en_us<CR>

" Copy selected text to system clipboard (requires gvim installed):
	set clipboard=unnamedplus
        vnoremap <C-c> "*Y :let @+=@*<CR>
	map <C-p> "+P

" Enable
        set wildmode=longest,list,full
	set wildmenu

" Only apply linux-coding-style plugin to these directories
	let g:linuxsty_patterns = [ "/usr/src/", "/linux" ]
	nnoremap <silent> <leader>l :LinuxCodingStyle<cr>

" Set diff mode to ignore whitespace
    if &diff
        " diff mode
        set diffopt+=iwhite
    endif

" Automatically retab on save.
	autocmd BufWritePre * retab

" Automatically deletes all trailing whitespace on save.
	autocmd BufWritePre * %s/\s\+$//e

" Disables automatic commenting on newline:
	" autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" Allows to see diff in current file before saving with :diffSaved
" https://stackoverflow.com/questions/749297/can-i-see-changes-before-i-save-my-file-in-vim
function! s:DiffWithSaved()
  let filetype=&ft
  diffthis
  vnew | r # | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
com! DiffSaved call s:DiffWithSaved()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NERDTree Stuff
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" autostart nerdtree if no file was specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" open nerdtree if a directory was opened
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" Bind NERDtree to Ctrl+n
map <C-n> :NERDTreeToggle<CR>

