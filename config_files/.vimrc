"##########################################################
" Vundle
set nocompatible
filetype off

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

"Other Plugins
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-endwise'
Plugin 'alvan/vim-closetag'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'Raimondi/delimitMate'
Plugin 'airblade/vim-gitgutter'
Plugin 'thoughtbot/vim-rspec'
Plugin 'scrooloose/nerdtree'
Plugin 'sjl/vitality.vim' "Fix some issues iwth the cursor and focus with vim in the console/tmux
Plugin 'sheerun/vim-polyglot'
Plugin 'editorconfig/editorconfig-vim'

" Maybe later
" Plugin 'Valloric/YouCompleteMe'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

"##########################################################
"General settings

"Set up tabs
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

" Line Numbers
set number
set relativenumber

"Hightlight Syntax
syntax enable

set ttimeoutlen=0

"Highlight based on cursor
set cursorline
set cursorcolumn
highlight CursorLine ctermbg=DarkGrey

"Show trailing spaces!!!!
set listchars=trail:·,tab:»·
set list

"Navigate in display line not actual
noremap j gj
noremap k gk

"##########################################################
" Set location of working files
" set backupdir=/Users/brian/dotfiles/.vim-temp//
" set directory=/Users/brian/dotfiles/.vim-temp//
" set undodir=/Users/brian/dotfiles/.vim-temp//

set backupdir=/tmp//
set directory=/tmp//
set undodir=/tmp//



"##########################################################
" nerdtree
let g:NERDTreeWinSize = 75


"##########################################################
" delimitMate
let delimitMate_matchpairs = "(:),[:],{:}"

"##########################################################
" ctrlp

" Make CtrlP use ag for listing the files. Way faster and no useless files.
let g:ctrlp_user_command = 'ag %s -l --hidden --nocolor -g ""'
let g:ctrlp_use_caching = 0

"##########################################################
" Leader Keybindings
let mapleader = " "
nnoremap <leader>e a<%=  %><esc>hhi
nnoremap <leader>w <esc>:w<enter>
nnoremap <leader># a#{}<esc>i
noremap <leader>n :NERDTreeToggle<cr>

" Always use the + register so our copys and pastes are better integrated with
" the system clipboard.
" set clipboard=unnamed,unnamedplus

"##########################################################
"closetag.vim
let g:closetag_filenames = "*.xml,*.html,*.erb,*.htm,*.xhtml,*.hbs,*.js,*.jsx"


"##########################################################
" Search!!!!!!

" Case insensitive unless pattern include capital letter
set ignorecase
set smartcase

" Automatically jump to next match when entering pattern
set incsearch

" Highlight all matches, clear with a space in command mode
set hlsearch
" Clear matches with a space
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

"##########################################################
" Better integration with tmux

" Evenly resize windows when vim resized
autocmd VimResized * :wincmd =

" Set up bindings for  pane zoom and rebalance
nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
nnoremap <leader>= :wincmd =<cr>

"##########################################################
" thoughtbot/vim-rspec
map <Leader>t :call RunCurrentSpecFile()<CR>
map <Leader>s :call RunNearestSpec()<CR>
map <Leader>l :call RunLastSpec()<CR>
map <Leader>a :call RunAllSpecs()<CR>

" Make sure we are running the spec with bundle exec so we have no 
" dependency issues between projects
let g:rspec_command = "!bundle exec rspec -I . -f d -c {spec}"

"##########################################################
" NERDTree
let NERDTreeShowHidden=1

"##########################################################
