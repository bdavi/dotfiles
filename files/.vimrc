"##########################################################
" Vundle Stuff

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
Plugin 'Valloric/YouCompleteMe'
Plugin 'Raimondi/delimitMate'
Plugin 'airblade/vim-gitgutter'
Plugin 'thoughtbot/vim-rspec'
Plugin 'scrooloose/nerdtree'
Plugin 'rizzatti/dash.vim'
Plugin 'mickaobrien/vim-stackoverflow'
Plugin 'sjl/vitality.vim' "Fix some issues iwth the cursor and focus with vim 
                          "in the console/tmux

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



"##########################################################
" delimitMate
let delimitMate_matchpairs = "(:),[:],{:}"

" Jump over closing delimters with a tab. SO THERE
" let g:delimitMate_expand_cr=1
" let g:delimitMate_expand_space=1
" inoremap <Tab> <C-R>=delimitMate#JumpAny("\<C-Tab>")<CR>

"##########################################################
" ctrlp

" Make CtrlP use ag for listing the files. Way faster and no useless files.
let g:ctrlp_user_command = 'ag %s -l --hidden --nocolor -g ""'
let g:ctrlp_use_caching = 0

" use ~/.agignore to exclude results (.git)


"##########################################################
" Leader Keybindings
let mapleader = " "
nnoremap <leader>e a<%=   %><esc>hhhi
nnoremap <leader>w <esc>:w<enter>
nnoremap <leader># a#{}<esc>i
noremap <leader>n :NERDTreeToggle<cr>

" Always use the + register so our copys and pastes are better integrated with
" the system clipboard.
set clipboard=unnamed,unnamedplus

"##########################################################
"closetag.vim

let g:closetag_filenames = "*.xml,*.html,*.erb,*.htm,*.xhtml"

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

