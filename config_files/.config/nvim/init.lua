vim.g.mapleader = " "

--------------------------------------------------------------------------
-- General settings
--------------------------------------------------------------------------
vim.opt.updatetime = 250

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
-- No colorscheme chosen yet, so this rides on Neovim's built-in default
-- theme. termguicolors makes that theme (and whatever replaces it later)
-- render in full 24-bit color instead of being downsampled to the
-- terminal's 256-color palette.
vim.opt.termguicolors = true

vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.colorcolumn = "80,100,120"

-- The default theme's ColorColumn is nearly as bright as regular text --
-- fine for one column, but three of them read as loud vertical bars. Soften
-- it to sit between Normal and CursorLine instead. Whenever a real
-- colorscheme is picked, this will need to move into a ColorScheme autocmd
-- (colorscheme changes wipe highlight overrides set this way).
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#1e2025" })

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
    "stevearc/oil.nvim",
    keys = {
      -- oil takes over the current window/buffer rather than opening a
      -- split or float, so open a fresh tab first to keep it out of the
      -- way of whatever's already open.
      { "<leader>n", "<cmd>tabnew | Oil<cr>", desc = "Open oil (new tab)" },
    },
    opts = {
      view_options = {
        show_hidden = true,
      },
    },
  },
})

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
