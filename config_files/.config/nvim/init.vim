"##########################################################
" General Settings
"##########################################################
" Decrease this value so gitgutter refreshes faster
set updatetime=250

" Tabs
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

" Line Numbers
set number
" Show trailing whitespace
set listchars=trail:·,tab:»·
set list

" Use system clipboard
set clipboard=unnamed,unnamedplus

" Don't use swapfiles
set noswapfile

" Misc
set wildmenu
set scrolloff=3
set autoread


"##########################################################
" Search
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
" Statusline
"##########################################################
set statusline=
set statusline+=\ %f
set statusline+=%=
set statusline+=\ %l:%c


"##########################################################
" Colors
"##########################################################
" Highlight based on cursor
set cursorline
set cursorcolumn

" Highlight width
set colorcolumn=80,100,120


"##########################################################
" Keybindings
"##########################################################
" Set leader to space
let mapleader = " "

" Re-source config
noremap <leader>si :source $MYVIMRC<cr>

" ERB
nnoremap <leader>e a<%=  %><esc>hhi
nnoremap <leader>E a<%  %><esc>hhi

" Insert current timestamp
nnoremap <leader>d "=strftime("%a %m/%e/%Y")<CR>P

" Navigate in display line not actual line
noremap j gj
noremap k gk


"##########################################################
" Plugins
" https://github.com/junegunn/vim-plug
" (Install new with `:PlugInstall`)
"##########################################################
call plug#begin()
  " 100% NON-NEGOTIABLE
  Plug 'christoomey/vim-tmux-navigator'

  " Theme
  Plug 'sainnhe/everforest'

  " Git
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rhubarb'
  ":G blame
  ":GBrowse
  Plug 'airblade/vim-gitgutter'

  " Fuzzy search
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope-fzy-native.nvim'
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.1' }

  " File Browsing
  Plug 'elihunter173/dirbuf.nvim'
  Plug 'scrooloose/nerdtree'
  Plug 'rafaqz/ranger.vim'

  " Editing
  Plug 'alvan/vim-closetag'
  Plug 'jiangmiao/auto-pairs'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-commentary'

  " Completion/LSP
  Plug 'neoclide/coc.nvim', { 'branch': 'release' }
  Plug 'neoclide/coc-solargraph', {'do': 'yarn install --frozen-lockfile'}
  " Plug 'elixir-lsp/coc-elixir', {'do': 'yarn install && yarn prepack'}

  " Consider adding
  "Plug 'rgroli/other.nvim'
  "Plug 'simrat39/symbols-outline.nvim'

call plug#end()

"##########################################################
" Everforest theme settings
"##########################################################
" Important!!
if has('termguicolors')
  set termguicolors
endif

" For dark version.
set background=dark

" Set contrast.
" This configuration option should be placed before `colorscheme everforest`.
" Available values: 'hard', 'medium'(default), 'soft'
let g:everforest_background = 'hard'

" For better performance
let g:everforest_better_performance = 1

colorscheme everforest


"##########################################################
" Telescope
"##########################################################
lua << EOF
  require('telescope').load_extension('fzy_native')
EOF

nmap <c-p> :Telescope find_files<cr>


"##########################################################
" closetag.vim
"##########################################################
let g:closetag_filenames = "*.xml,*.html,*.erb,*.htm,*.xhtml,*.hbs,*.js,*.jsx,*.tsx"


"##########################################################
" Ranger
"##########################################################
" let g:ranger_map_keys = 0
" nnoremap <leader>r :Ranger<cr>

map <leader>rr :RangerEdit<cr>
map <leader>rv :RangerVSplit<cr>
map <leader>rs :RangerSplit<cr>
map <leader>rt :RangerTab<cr>
map <leader>ri :RangerInsert<cr>
map <leader>ra :RangerAppend<cr>
map <leader>rc :set operatorfunc=RangerChangeOperator<cr>g@
map <leader>rd :RangerCD<cr>
map <leader>rld :RangerLCD<cr>






"##########################################################
" NERDTree
"##########################################################
let g:NERDTreeWinSize = 75
let NERDTreeShowHidden=1
noremap <leader>n :NERDTreeToggle<cr>


"##########################################################
" coc.nvim
"##########################################################
"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"!! BE SURE TO SET "suggest.noselect": true in ~/.vim/coc-settings.json
"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif








