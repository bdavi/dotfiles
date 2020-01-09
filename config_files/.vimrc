"##########################################################
"General settings
"##########################################################
set updatetime=300

"Set up tabs
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

"Line Numbers
set number
set relativenumber

"Hightlight Syntax
syntax enable

"Show trailing whitespace
set listchars=trail:·,tab:»·
set list

"Navigate in display line not actual line
noremap j gj
noremap k gk

"SILENCE!!!!!
set vb t_vb=

"Generally, don't use swapfiles
set noswapfile

"But when you do use swapfiles, keep them tidy
set backupdir=/tmp//
set directory=/tmp//
set undodir=/tmp//

"Use system clipboard
set clipboard=unnamed,unnamedplus

"Misc
set wildmenu
set ruler
set scrolloff=3
set autoread


"##########################################################
"Search
"##########################################################
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
" Colors
"##########################################################
"Highlight based on cursor
set cursorline
set cursorcolumn
highlight CursorLine ctermbg=235
highlight CursorColumn ctermbg=235

"Highlight width
set colorcolumn=80,100,120
highlight ColorColumn ctermbg=234


"##########################################################
" Keybindings
"##########################################################
"Set leader
let mapleader = " "

"Easier split navigation (unnecessary with tmux-navigator)
"nnoremap <C-J> <C-W><C-J>
"nnoremap <C-K> <C-W><C-K>
"nnoremap <C-L> <C-W><C-L>
"nnoremap <C-H> <C-W><C-H>

"ERB
nnoremap <leader>e a<%=  %><esc>hhi
nnoremap <leader>E a<%  %><esc>hhi


"##########################################################
"Install and configure plugins
"Using https://github.com/junegunn/vim-plug (Install new with `:PlugInstall`
"##########################################################
call plug#begin('~/.vim/plugged')
  Plug 'scrooloose/nerdtree'
  Plug 'editorconfig/editorconfig-vim'
  Plug 'airblade/vim-gitgutter'
  Plug '/usr/local/opt/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'sheerun/vim-polyglot'
  Plug 'janko/vim-test'
  Plug 'skywind3000/asyncrun.vim'
  Plug 'tpope/vim-dispatch'
  Plug 'dense-analysis/ale'
  Plug 'tpope/vim-rails'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'danilo-augusto/vim-afterglow' "Theme
  Plug 'tpope/vim-commentary'
  Plug 'jiangmiao/auto-pairs'
  Plug 'tpope/vim-endwise'
  Plug 'wincent/terminus' "Improve cursor
  Plug 'alvan/vim-closetag'
  Plug 'valloric/youcompleteme'
  Plug 'tpope/vim-surround'
  Plug 'craigemery/vim-autotag'
  Plug 'jpalardy/vim-slime'
  Plug 'metakirby5/codi.vim'
call plug#end()

"vim-slime
let g:slime_target = "tmux"
let g:slime_paste_file = "$HOME/.slime_paste"
let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}"}

"NERDTree
let g:NERDTreeWinSize = 75
let NERDTreeShowHidden=1
noremap <leader>n :NERDTreeToggle<cr>

"fzf
set rtp+=~/.fzf
nmap <c-p> :GFiles<cr>

"closetag.vim
let g:closetag_filenames = "*.xml,*.html,*.erb,*.htm,*.xhtml,*.hbs,*.js,*.jsx"

"vim-test
let test#strategy = "asyncrun"
let g:asyncrun_open = 20
nmap <Leader>t :TestFile<CR>
nmap <Leader>s :TestNearest<CR>
nmap <Leader>l :TestLast<CR>
nmap <Leader>a :TestSuite<CR>
nmap <Leader>v :TestVisit<CR>

"vim-tmux-navigator
autocmd VimResized * :wincmd =
nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
nnoremap <leader>= :wincmd =<cr>

"afteglow
colorscheme afterglow


"##############################################################################
"##############################################################################
" The following cause rendering artifacts in vim-gtk on Ubuntu. Figure them
" out. OR ELSE
"##############################################################################
"##############################################################################

"set term=screen-256color

"##########################################################
" Statusline
"##########################################################
"set laststatus=2

"Git funrctions from https://shapeshed.com/vim-statuslines/
"function! GitBranch()
"  return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
"endfunction
"
"function! StatuslineGit()
"  let l:branchname = GitBranch()
"  return strlen(l:branchname) > 0?' ['.l:branchname.']':''
"endfunction
"
"set statusline=
"set statusline+=%#PmenuSel#
"set statusline+=%{StatuslineGit()}
"set statusline+=%#LineNr#
"set statusline+=\ %m
"set statusline+=\ %f
"set statusline+=%=
"set statusline+=%#CursorColumn#
"set statusline+=\ %l:%c
