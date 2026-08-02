"##########################################################
" General settings
"##########################################################
" herdr panes report &term as xterm-256color (not the screen-256color
" $TERM env var) via termresponse auto-detection, which matches vim's
" default 'keyprotocol' xterm:mok2 rule (see :help keyprotocol) - Vim
" then negotiates xterm's modifyOtherKeys level 2 to disambiguate
" Ctrl+key chords from legacy control characters. herdr's own terminal
" emulation doesn't fully round-trip that negotiation, which is the
" likely source of stray ^[[... sequences showing up as literal text
" (only possible in insert mode - the Ctrl-h/j/k/l navigation mapping
" below is normal-mode-only and unaffected either way). Disabled here
" since nothing in this config needs mok2/kitty Ctrl-key disambiguation.
if !empty($HERDR_PANE_ID)
  set keyprotocol=xterm:none
endif

" Decrease this value so gitgutter refreshes faster
set updatetime=250

" Set up tabs
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

" Line Numbers
set number

" Show trailing whitespace
set listchars=trail:·,tab:»·
set list
" Navigate in display line not actual line
noremap j gj
noremap k gk

" SILENCE!!!!!
set vb t_vb=

" Don't use swapfiles
set noswapfile

" Use system clipboard
set clipboard=unnamed,unnamedplus

" Set cursor in different modes (may not work in all terminals)
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"

" Misc
set wildmenu
set scrolloff=3
set autoread

" Hightlight Syntax
syntax enable


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
" Colors
"##########################################################
" Highlight based on cursor
set cursorline
set cursorcolumn
highlight CursorLine ctermbg=235
highlight CursorColumn ctermbg=235

" Highlight width
set colorcolumn=80,100,120
highlight ColorColumn ctermbg=234


"##########################################################
" Keybindings
"##########################################################
" Set leader
let mapleader = " "

" ERB
nnoremap <leader>e a<%=  %><esc>hhi
nnoremap <leader>E a<%  %><esc>hhi

" Misc
nnoremap <leader>d "=strftime("%a %m/%e/%Y")<CR>P

"##########################################################
" Statusline
"##########################################################
set laststatus=2

function! StatuslineGit()
    if exists("g:git_branch")
        return g:git_branch
    else
        return ''
    endif
endfunction

function! GetGitBranch()
    let l:is_git_dir = system('echo -n $(git rev-parse --is-inside-work-tree)')

    if l:is_git_dir == 'true'
      let g:git_branch =  system('bash -c "echo -n $(git rev-parse --abbrev-ref HEAD)"')
    else
      let g:git_branch =  ''
    endif
endfunction

autocmd BufEnter * call GetGitBranch()

set statusline=
set statusline+=%#PmenuSel#
set statusline+=\ 
set statusline+=%{StatuslineGit()}
set statusline+=\ 
set statusline+=%#CursorColumn#
set statusline+=\ %m
set statusline+=\ %f
set statusline+=%=
set statusline+=\ %l:%c


"##########################################################
" Install and configure plugins
" Using https://github.com/junegunn/vim-plug (Install new with `:PlugInstall`
"##########################################################
call plug#begin('~/.vim/plugged')
  Plug 'airblade/vim-gitgutter'
  Plug 'alvan/vim-closetag'
  Plug 'christoomey/vim-tmux-navigator'
  Plug 'danilo-augusto/vim-afterglow' "Theme
  Plug 'dense-analysis/ale'
  Plug 'editorconfig/editorconfig-vim'
  Plug 'francoiscabrol/ranger.vim'
  Plug 'janko/vim-test'
  Plug 'jiangmiao/auto-pairs'
  Plug 'jpalardy/vim-slime'
  Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
  Plug 'neoclide/coc.nvim', { 'branch': 'release' }
  Plug 'scrooloose/nerdtree'
  Plug 'sheerun/vim-polyglot'
  Plug 'skywind3000/asyncrun.vim' "Use with vim-test
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-repeat'
  Plug 'scrooloose/syntastic'
  Plug 'gcorne/vim-sass-lint'
  Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
call plug#end()

" vim-herdr-navigation (Ctrl-h/j/k/l across herdr panes and Vim splits) -
" the herdr side (`herdr plugin install`, install_herdr_vim_navigation_plugin
" in lib/herdr.sh) decides whether to forward a keystroke into Vim at
" all; this is the Vim side, which decides whether to move within Vim's
" own splits or hand off to herdr at an edge. Reimplemented here instead
" of sourcing the plugin's own editor/vim.vim, for two independent
" reasons:
"   1. Its HerdrFocus calls `herdr pane focus --direction <dir> --current`,
"      which resolves to the server's globally focused pane rather than
"      the pane Vim is actually running in - a confirmed upstream bug
"      (paulbkim-dev/vim-herdr-navigation#7; the open fix PR covers
"      navigate.sh/nvim.lua but not this file). Uses --pane
"      $HERDR_PANE_ID instead.
"   2. A plain top-level nnoremap here (or the plugin's own vim.vim,
"      sourced the same way) gets silently overwritten: :scriptnames
"      shows vim-tmux-navigator's plugin/ file - and its own
"      unconditional nnoremap for these same keys - actually sourced
"      *after* this point in the file, despite plug#end() appearing
"      earlier in .vimrc and vim-tmux-navigator being a normal, non-lazy
"      Plug. A VimEnter autocmd doesn't fix it either (verified via
"      :verbose autocmd VimEnter that vim-tmux-navigator's mapping isn't
"      itself VimEnter-deferred, so ordering vim-plug's internal loading
"      against a VimEnter hook here doesn't help). The 0ms timer below
"      sidesteps whatever vim-plug's actual ordering is: it fires on the
"      next event-loop tick, strictly after all synchronous startup
"      processing has completed.
" Not a fork of the plugin - the herdr-side dispatcher (navigate.sh)
" still comes from the real plugin install; only its Vim-side
" counterpart is reimplemented, and only because sourcing it unmodified
" wouldn't reliably apply at all (issue 2), bug or no bug (issue 1).
function! s:HerdrFocusFixed(dir) abort
  let l:herdr = empty($HERDR_BIN_PATH) ? 'herdr' : $HERDR_BIN_PATH
  call system(shellescape(l:herdr) . ' pane focus --direction ' . a:dir . ' --pane ' . shellescape($HERDR_PANE_ID))
endfunction

function! s:NavigateFixed(wincmd, dir) abort
  let l:prev = winnr()
  execute 'wincmd ' . a:wincmd
  if winnr() == l:prev
    call s:HerdrFocusFixed(a:dir)
  endif
endfunction

function! s:ApplyHerdrNavMappings() abort
  if empty($HERDR_PANE_ID)
    return
  endif
  nnoremap <silent> <C-h> :call <SID>NavigateFixed('h', 'left')<CR>
  nnoremap <silent> <C-j> :call <SID>NavigateFixed('j', 'down')<CR>
  nnoremap <silent> <C-k> :call <SID>NavigateFixed('k', 'up')<CR>
  nnoremap <silent> <C-l> :call <SID>NavigateFixed('l', 'right')<CR>
endfunction

call timer_start(0, {-> s:ApplyHerdrNavMappings()})

" sass-lint
let g:syntastic_sass_checkers=["sasslint"]
let g:syntastic_scss_checkers=["sasslint"]


" coc.nvim
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


" afteglow
colorscheme afterglow


" vim-gitgutter
" Be sure to set this AFTER the colorscheme or it won't render colors correctly
set signcolumn=yes
hi GitGutterAdd    guibg=#121212 ctermbg=233 guifg=#00ff00 ctermfg=46
hi GitGutterDelete guibg=#121212 ctermbg=233 guifg=#ff0000 ctermfg=196
hi GitGutterChange guibg=#121212 ctermbg=233 guifg=#ff8700 ctermfg=208

let g:gitgutter_sign_removed = '🡶'
let g:gitgutter_sign_added = '+'
let g:gitgutter_sign_modified = '≈'


" ale
" Be sure to set this AFTER the colorscheme or it won't render colors correctly
highlight ALEWarning ctermbg=52
highlight ALEError ctermbg=52


" vim-slime
let g:slime_target = "tmux"
let g:slime_paste_file = "$HOME/.slime_paste"
let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}"}


" NERDTree
let g:NERDTreeWinSize = 75
let NERDTreeShowHidden=1
noremap <leader>n :NERDTreeToggle<cr>


" Ranger
let g:ranger_map_keys = 0
nnoremap <leader>r :Ranger<cr>


" fzf
set rtp+=~/.fzf
nmap <c-p> :GFiles --exclude-standard --others --cached<cr>
nmap <c-f> :Files<cr>
nmap <c-g> :Ag<cr>


" closetag.vim
let g:closetag_filenames = "*.xml,*.html,*.erb,*.htm,*.xhtml,*.hbs,*.js,*.jsx,*.tsx"


" vim-test
" let test#strategy = "asyncrun"
" let g:asyncrun_open = 20

" let test#ruby#minitest#executable='ect'

nmap <Leader>t :TestFile<CR>
nmap <Leader>s :TestNearest<CR>
nmap <Leader>l :TestLast<CR>
nmap <Leader>a :TestSuite<CR>
nmap <Leader>v :TestVisit<CR>


" vim-tmux-navigator
autocmd VimResized * :wincmd =
nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
nnoremap <leader>= :wincmd =<cr>

" Work
set autoread
autocmd BufWritePost *.ex,*.exs call FormatAndRedraw()
function FormatAndRedraw()
  let currentpath = expand('%:p')
  let rlfilematch = matchstr(currentpath, 'redline')

  if len(rlfilematch)
    let redlinepath = $HOME . "/monorepo/redline/"
    let formatpath = substitute(currentpath, "^" . redlinepath, "", "")

    silent exec "!${PROJECT_ROOT}/monorepo/zlaverse/support/frmt_vim.sh " . formatpath
    redraw!
  endif
endfunction
