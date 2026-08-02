vim.g.mapleader = " "

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
