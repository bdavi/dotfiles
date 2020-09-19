"##########################################################
" General settings
"##########################################################
set updatetime=500

" Set up tabs
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab

" Line Numbers
set number
" set relativenumber

" Hightlight Syntax
syntax enable

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


"##########################################################
" Super lightweight autocomplete using the built in and autocmd
"##########################################################
set cot=menu,menuone

ino <BS> <BS><C-r>=getline('.')[col('.')-3:col('.')-2]=~#'\k\k'?!pumvisible()?"\<lt>C-n>\<lt>C-p>":'':pumvisible()?"\<lt>C-y>":''<CR>
ino <CR> <C-r>=pumvisible()?"\<lt>C-y>":""<CR><CR>
ino <Tab> <C-r>=pumvisible()?"\<lt>C-n>":"\<lt>Tab>"<CR>
ino <S-Tab> <C-r>=pumvisible()?"\<lt>C-p>":"\<lt>S-Tab>"<CR>

augroup MyAutoComplete
    au!
    au InsertCharPre * if
    \ !exists('s:complete') &&
    \ !pumvisible() &&
    \ getline('.')[col('.')-2].v:char =~# '\k\k' |
        \ let s:complete = 1 |
        \ noautocmd call feedkeys("\<C-n>\<C-p>", "nt") |
    \ endif
    au CompleteDone * if exists('s:complete') | unlet s:complete | endif
augroup END


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
" Markdown Preview
"##########################################################
function! PreviewMarkdown()
  if filereadable('preview.html')
    !pandoc %:p -f gfm -t html -s -o preview.html --metadata pagetitle="Preview"
  endif
endfunction

autocmd BufWritePost *.md silent call PreviewMarkdown()


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
  Plug 'scrooloose/nerdtree'
  Plug 'sheerun/vim-polyglot'
  Plug 'skywind3000/asyncrun.vim' "Use with vim-test
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-surround'
call plug#end()

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

" fzf
" set rtp+=~/.fzf
nmap <c-p> :GFiles<cr>
nmap <c-f> :Files<cr>
nmap <c-g> :Ag<cr>

" closetag.vim
let g:closetag_filenames = "*.xml,*.html,*.erb,*.htm,*.xhtml,*.hbs,*.js,*.jsx"

" vim-test
let test#strategy = "asyncrun"
let g:asyncrun_open = 20
nmap <Leader>t :TestFile<CR>
nmap <Leader>s :TestNearest<CR>
nmap <Leader>l :TestLast<CR>
nmap <Leader>a :TestSuite<CR>
nmap <Leader>v :TestVisit<CR>

" vim-tmux-navigator
autocmd VimResized * :wincmd =
nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
nnoremap <leader>= :wincmd =<cr>
