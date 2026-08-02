# Neovim cheatsheet

Config lives at `config_files/.config/nvim/`. Plugin manager is
[lazy.nvim](https://github.com/folke/lazy.nvim) (`:Lazy` to manage plugins,
`:Lazy sync` to install/update everything, `:Mason` for LSP server installs,
`:checkhealth` to diagnose problems).

Leader is `<Space>`.

## General

| Key | Action |
|---|---|
| `j` / `k` | Move by display line, not actual line (wrapped lines behave sanely) |
| `<Space>` | Clear search highlight |
| `<leader>d` | Insert today's date (`Sun 08/ 2/2026`-style timestamp) |
| `<leader>e` | Insert ERB output tag `<%=  %>`, cursor in the middle |
| `<leader>E` | Insert ERB tag `<%  %>`, cursor in the middle |

Other settings: 2-space tabs/expandtab, line numbers, trailing-whitespace
markers (`list`/`listchars`), no swapfiles, system clipboard is the default
register (yank/paste moves text in and out of other tmux/herdr panes),
`scrolloff=3`, smartcase search, `cursorline`/`cursorcolumn`/`colorcolumn`
(80/100/120) all on.

## Colorscheme

`afterglow` - a native, dependency-free port (`colors/afterglow.lua`) of
[danilo-augusto/vim-afterglow](https://github.com/danilo-augusto/vim-afterglow),
hand-extracted rather than pulled in as a plugin. Only the base highlight
groups are set; Treesitter's default captures inherit from them.

## Navigation

| Key | Action |
|---|---|
| `<C-h/j/k/l>` | Move between Neovim splits, herdr panes, and tmux panes seamlessly (via `vim-herdr-navigation` + `vim-tmux-navigator`) |
| `<C-p>` | Fuzzy-find files (fzf-lua) |
| `<C-t>` (in the fzf-lua picker) | Open selection in a new tab |
| `<leader>n` | Open [oil.nvim](https://github.com/stevearc/oil.nvim) in a new tab - edit the filesystem as a buffer (rename/delete/create by editing lines and `:w`). `-` goes to parent dir, hidden files shown by default |

## Git ([gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim))

| Key | Action |
|---|---|
| `<leader>gb` | Toggle inline current-line git blame |

Gutter signs for added/changed/deleted lines are on by default.

## Editing

- **Autopairs** ([nvim-autopairs](https://github.com/windwp/nvim-autopairs)) - brackets/quotes close automatically as you type.
- **Surround** ([nvim-surround](https://github.com/kylechui/nvim-surround), tpope-compatible keybindings):
  - `ys{motion}{char}` - add a surrounding (e.g. `ysiw"` to quote a word)
  - `cs{old}{new}` - change a surrounding (e.g. `cs"'` quotes → single quotes)
  - `ds{char}` - delete a surrounding
  - Dot-repeatable.
- **Endwise** ([nvim-treesitter-endwise](https://github.com/RRethy/nvim-treesitter-endwise)) - typing `def foo` + Enter in Ruby/Lua/Elixir/Bash/Vimscript/Fish/Julia auto-inserts the matching `end`.
- **Commenting** - built into Neovim since 0.10, no plugin: `gcc` toggles a line, `gc{motion}`/visual `gc` toggles a range.
- **`.editorconfig`** - native support since Neovim 0.9, no plugin needed.

## Completion ([blink.cmp](https://github.com/saghen/blink.cmp))

Sources: LSP, path, snippets ([friendly-snippets](https://github.com/rafamadriz/friendly-snippets)), buffer words.

| Key | Action |
|---|---|
| `<CR>` | Accept the selected completion (top match is auto-highlighted the instant the menu opens - no need to navigate to it first) |
| `<C-space>` | Manually open the completion menu / toggle docs |
| `<Up>` / `<Down>`, `<C-p>` / `<C-n>` | Move selection |
| `<Tab>` / `<S-Tab>` | Jump forward/backward through snippet placeholders |
| `<C-e>` | Cancel |

## LSP

Installed servers ([mason.nvim](https://github.com/mason-org/mason.nvim) +
[mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim) +
`nvim-lspconfig`, native `vim.lsp.config`/`vim.lsp.enable` - not the old
`require('lspconfig').setup{}` pattern): **Elixir** (`elixirls`), **CSS**
(`cssls`), **JS/TS/TSX** (`ts_ls`), **Ruby** (`ruby_lsp`).

Two things worth knowing about these specifically:
- `elixir-ls` compiles itself from source on its very first run (`mix
  deps.get`/compile) - can take several minutes with zero visible progress.
  Looks hung, isn't.
- `ruby_lsp` refuses to attach if the project has a `Gemfile` but no
  `Gemfile.lock` yet - run `bundle install` first.

Keybindings (buffer-local, only exist where a server is actually attached):

| Key | Action |
|---|---|
| `gd` | Go to definition (fzf-lua picker) |
| `gD` | Go to declaration |
| `gi` | Go to implementation (fzf-lua picker) |
| `gr` | Go to references (fzf-lua picker) |
| `K` | Hover docs |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action (fzf-lua picker) |
| `<leader>cs` | Document symbols (fzf-lua picker) |

## Diagnostics

| Key | Action |
|---|---|
| `[d` / `]d` | Previous/next diagnostic (opens a float at the same time) |
| `<leader>cd` | Show diagnostics for the current line |

## Formatting ([conform.nvim](https://github.com/stevearc/conform.nvim))

Format-on-save is on. Explicit formatter configured for Elixir (`mix
format`); every other filetype falls back to its attached LSP server's
formatter, if any. `:ConformInfo` shows what would run for the current
buffer.

## Treesitter

Parsers installed: bash, css, elixir, ERB (`embedded_template`), erlang, go,
html, javascript, json, lua, markdown(+inline), perl, python, ruby, tsx,
typescript, vim, vimdoc, yaml. `auto_install` is on, so opening any other
supported filetype installs its parser on the fly.

Pinned to nvim-treesitter's `master` branch, not `main` - `main` requires
Neovim 0.12+, and this box runs 0.11.

## Notifications ([snacks.nvim](https://github.com/folke/snacks.nvim))

Only the `notifier` module is enabled - nicer popups for `vim.notify()`
calls (Mason/LSP status messages, etc.). Nothing else from snacks.nvim
(dashboard, picker, ...) is turned on.

## Statusline ([lualine.nvim](https://github.com/nvim-lualine/lualine.nvim))

Theme is `"auto"` - derived from afterglow's own highlight groups, since
afterglow doesn't ship a dedicated lualine theme.

## Not ported from the old Vim setup (why)

- **NERDTree** - skipped; oil.nvim owns `<leader>n` instead.
- **vim-commentary** - built-in `gc`/`gcc` replaces it (Neovim 0.10+).
- **editorconfig-vim** - built-in `.editorconfig` support replaces it (Neovim 0.9+).
- **vim-repeat** - only needed for plugins that don't implement dot-repeat themselves; nvim-surround does it natively.
- **ALE / syntastic** - syntastic was already dead weight (ALE superseded it even in the old config); ALE's job is now split between LSP diagnostics and conform.nvim/nvim-lint.
- **vim-closetag** - superseded by treesitter-based tag closing if/when `nvim-ts-autotag` gets added (not yet).
