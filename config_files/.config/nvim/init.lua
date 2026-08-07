vim.g.mapleader = " "

--------------------------------------------------------------------------
-- General settings
--------------------------------------------------------------------------
vim.opt.updatetime = 250

-- Reload a buffer from disk when another process changes the underlying
-- file, as long as this buffer has no unsaved local edits - `checktime`'s
-- own behavior, not reimplemented here, so a modified buffer still gets
-- the usual "changed since editing started" prompt instead of being
-- silently overwritten. `autoread` alone is a no-op in terminal Vim/Neovim
-- without something to actually trigger `checktime` - it only checks on
-- specific events, it doesn't poll. FocusGained catches switching back to
-- the terminal from outside (if the terminal forwards focus events - not
-- guaranteed through tmux/herdr panes), BufEnter catches switching
-- buffers/windows inside Neovim itself, and CursorHold/CursorHoldI (after
-- `updatetime` ms idle, set above) catches sitting on an unchanged buffer
-- while another process edits the file underneath it.
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  desc = "Reload buffers changed on disk by another process",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  desc = "Notify after a buffer is auto-reloaded from disk",
  callback = function()
    vim.notify("File changed on disk, buffer reloaded", vim.log.levels.WARN)
  end,
})

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

vim.opt.number = true

vim.opt.listchars = { trail = "·", tab = "»·" }
vim.opt.list = true

vim.opt.swapfile = false

-- Route the unnamed register to the system clipboard so yank/delete/paste
-- always hits it -- no separate register to think about, and it's what
-- lets you move text between vim buffers and other tmux/herdr panes.
vim.opt.clipboard = "unnamed,unnamedplus"

-- Copy via OSC 52 (forced, since autodetection is unreliable through
-- ssh + herdr), but paste from the local unnamed register: herdr forwards
-- OSC 52 writes but doesn't answer reads, so the stock osc52 paste would
-- stall ~10s on every p/P waiting for a response that never comes.
-- External content comes in via the terminal's own paste (bracketed
-- paste) instead.
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = function() return vim.split(vim.fn.getreg('"'), "\n") end,
    ["*"] = function() return vim.split(vim.fn.getreg('"'), "\n") end,
  },
}

vim.opt.scrolloff = 3

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.keymap.set({ "n", "x", "o" }, "j", "gj", { desc = "Move by display line" })
vim.keymap.set({ "n", "x", "o" }, "k", "gk", { desc = "Move by display line" })

vim.keymap.set("n", "<Space>", ":nohlsearch<Bar>:echo<CR>", { silent = true, desc = "Clear search highlight" })

vim.keymap.set("n", "<leader>d", '"=strftime("%a %m/%e/%Y")<CR>P', { desc = "Insert timestamp" })

vim.keymap.set("n", "<leader>e", "a<%=  %><esc>hhi", { desc = "Insert ERB output tag" })
vim.keymap.set("n", "<leader>E", "a<%  %><esc>hhi", { desc = "Insert ERB tag" })

--------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------
vim.opt.termguicolors = true

-- Hand-extracted from danilo-augusto/vim-afterglow -- see colors/afterglow.lua
vim.cmd.colorscheme("afterglow")

vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.colorcolumn = "80,100,120"

--------------------------------------------------------------------------
-- Resolve symlinked buffers to their real path (e.g. ~/.config/nvim/init.lua,
-- symlinked from this dotfiles repo via install_dotfiles.sh). Without this,
-- opening a file through a symlink and later reaching the same file by its
-- real path (e.g. via fzf-lua) creates two separate buffers for one file,
-- which fzf-lua can't reconcile ("Unable to add buffer").
--------------------------------------------------------------------------
vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Resolve symlinks to a single canonical buffer per file",
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then return end
    local name = vim.api.nvim_buf_get_name(args.buf)
    local real = vim.loop.fs_realpath(name)
    if real and real ~= name then
      pcall(vim.api.nvim_buf_set_name, args.buf, real)
    end
  end,
})

--------------------------------------------------------------------------
-- Plugin manager (lazy.nvim)
--------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      -- lspconfig server names, not Mason package names (mason-lspconfig
      -- translates between the two) -- e.g. ruby_lsp <-> ruby-lsp.
      ensure_installed = { "elixirls", "cssls", "ts_ls", "ruby_lsp" },
    },
    config = function(_, opts)
      -- Neovim 0.11+'s native vim.lsp.config replaces the old
      -- require('lspconfig').server.setup{} pattern (deprecated/removed).
      -- '*' applies to every server config as a default, so blink.cmp's
      -- completion capabilities reach whichever server attaches.
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })
      -- Installs ensure_installed above, then vim.lsp.enable()'s each one.
      require("mason-lspconfig").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    -- nvim-treesitter's `main` branch requires Neovim 0.12+; `master` is the
    -- frozen-but-supported branch for 0.10/0.11 and is what this box runs.
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      -- Treesitter-aware replacement for tpope/vim-endwise -- auto-inserts
      -- "end"/"endif"/etc. by reading the real syntax tree instead of
      -- regex, so it works reliably for Ruby and Lua under Neovim.
      "RRethy/nvim-treesitter-endwise",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "css", "elixir", "embedded_template", "erlang", "go",
          "html", "javascript", "json", "lua", "markdown", "markdown_inline",
          "perl", "python", "query", "ruby", "tsx", "typescript", "vim",
          "vimdoc", "yaml",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      -- vim-herdr-navigation (below) maps Ctrl-h/j/k/l unconditionally and
      -- falls back to :TmuxNavigate* commands itself, so we only want
      -- tmux-navigator's commands, not its own competing keymaps.
      vim.g.tmux_navigator_no_mappings = 1
    end,
  },
  {
    "ibhagwan/fzf-lua",
    keys = {
      { "<C-p>", "<cmd>FzfLua files<cr>", desc = "Find files" },
    },
    opts = {},
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        vim.keymap.set("n", "<leader>gb", require("gitsigns").toggle_current_line_blame,
          { buffer = bufnr, desc = "Toggle git blame" })
      end,
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "kylechui/nvim-surround",
    version = "^4.0.0",
    event = "VeryLazy",
    opts = {},
  },
  {
    -- Single animated line marking the indent scope under the cursor
    -- (dedent-aware, so it works in Python/YAML/ERB too, not just
    -- brace languages) -- lighter than indent-blankline, which draws a
    -- line per indent level instead of just the current scope. Also
    -- throws in ii/ai text objects and [i/]i motions for free.
    "echasnovski/mini.indentscope",
    event = { "BufReadPost", "BufNewFile" },
    -- opts as a function, not a table: a table is evaluated immediately
    -- while lazy.nvim builds the spec (before the plugin's installed on a
    -- fresh setup, and eagerly on every run after, defeating `event`
    -- above) -- a function is only called once the plugin actually loads.
    opts = function()
      return {
        symbol = "│",
        draw = { animation = require("mini.indentscope").gen_animation.none() },
      }
    end,
  },
  {
    "saghen/blink.cmp",
    -- v2 is under active development with breaking changes; pin to the
    -- stable v1 line (ships prebuilt fuzzy-matcher binaries).
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- "enter" preset maps <CR> to accept the selected item (falling back
      -- to a normal newline when nothing's selected/menu is closed).
      keymap = { preset = "enter" },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = { auto_show = false },
        -- Auto-highlight the top match so <CR> accepts it immediately,
        -- without needing to navigate to it first.
        list = { selection = { preselect = true } },
      },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
  {
    -- File-type icons for fzf-lua and oil.nvim (both auto-detect and use
    -- this if it's present -- no extra config needed on their end).
    -- Needs a Nerd Font selected as the terminal's font to render
    -- correctly; see lib/neovim.sh's install_nerd_font.
    "nvim-tree/nvim-web-devicons",
    opts = {},
  },
  {
    -- Symbol outline sidebar (backed by LSP when attached, treesitter
    -- otherwise) -- orienting fast in a large/unfamiliar file without
    -- hunting line by line, e.g. after an AI-generated edit.
    "stevearc/aerial.nvim",
    keys = {
      { "<leader>a", "<cmd>AerialToggle<cr>", desc = "Toggle symbol outline" },
    },
    opts = {},
  },
  {
    "stevearc/oil.nvim",
    keys = {
      -- oil takes over the current window/buffer rather than opening a
      -- split or float, so open a fresh tab first to keep it out of the
      -- way of whatever's already open. Seed it with the directory of the
      -- buffer that was current beforehand -- tabnew's new buffer is
      -- unnamed, so a bare `:Oil` there would fall back to nvim's launch
      -- cwd instead. If oil's already the current buffer (i.e. its own
      -- tab), close that tab instead of stacking another one -- symmetric
      -- with the tabnew that opened it.
      {
        "<leader>n",
        function()
          if vim.bo.filetype == "oil" then
            vim.cmd("tabclose")
            return
          end
          local dir = vim.fn.expand("%:p:h")
          vim.cmd("tabnew")
          vim.cmd("Oil " .. vim.fn.fnameescape(dir))
        end,
        desc = "Open oil (new tab)",
      },
    },
    opts = {
      view_options = {
        show_hidden = true,
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      -- "auto" derives a theme from the current colorscheme's own highlight
      -- groups (Normal, StatusLine, etc.) -- afterglow doesn't ship a
      -- dedicated lualine theme, so this is what picks up its palette.
      options = { theme = "auto" },
      -- Drop encoding/fileformat/filetype (the default lualine_x); keep
      -- mode, branch/diff/diagnostics, filename, progress, and location.
      sections = { lualine_x = {} },
    },
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        elixir = { "mix" },
      },
      -- Falls back to the attached LSP server's formatter for filetypes
      -- with no formatter configured above.
      format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function() vim.fn["mkdp#util#install"]() end,
    keys = {
      -- <leader>m, not the plugin's own suggested <C-p> -- that's already
      -- bound to fzf-lua's file finder above.
      { "<leader>m", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle markdown preview" },
    },
  },
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    ---@type snacks.Config
    opts = {
      -- Only the notifier module -- nicer vim.notify() popups. Every other
      -- snacks.nvim feature (dashboard, picker, etc.) stays off since it's
      -- not listed here.
      notifier = {},
    },
  },
})

--------------------------------------------------------------------------
-- LSP keybindings and diagnostics
--------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP keybindings, buffer-local so they only exist where a server actually attaches",
  callback = function(args)
    local b = { buffer = args.buf }
    vim.keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<cr>", vim.tbl_extend("force", b, { desc = "Go to definition" }))
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", b, { desc = "Go to declaration" }))
    vim.keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<cr>", vim.tbl_extend("force", b, { desc = "Go to implementation" }))
    vim.keymap.set("n", "gr", "<cmd>FzfLua lsp_references<cr>", vim.tbl_extend("force", b, { desc = "Go to references" }))
    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", b, { desc = "Hover docs" }))
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", b, { desc = "Rename symbol" }))
    vim.keymap.set({ "n", "x" }, "<leader>ca", "<cmd>FzfLua lsp_code_actions<cr>", vim.tbl_extend("force", b, { desc = "Code action" }))
    vim.keymap.set("n", "<leader>cs", "<cmd>FzfLua lsp_document_symbols<cr>", vim.tbl_extend("force", b, { desc = "Document symbols" }))
  end,
})

vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

--------------------------------------------------------------------------
-- vim-herdr-navigation (Ctrl-h/j/k/l across herdr panes, tmux panes, and
-- Neovim splits - https://github.com/paulbkim-dev/vim-herdr-navigation)
-- Falls back to tmux-navigator when outside herdr, and to plain wincmd
-- when outside both, so this works everywhere.
-- Globbed since herdr installs plugins under a path with a content hash.
--------------------------------------------------------------------------
local herdr_nav = vim.fn.glob("~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua")
if herdr_nav ~= "" then
  dofile(vim.fn.expand(herdr_nav))
end
