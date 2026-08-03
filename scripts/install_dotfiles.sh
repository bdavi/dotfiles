#!/usr/bin/env bash

# Neovim config migrated from init.vim to init.lua (old file archived at
# config_files/.config/nvim/archive/init.vim.bak). A leftover
# ~/.config/nvim/init.vim from before that migration - whether a real file
# or a symlink cp -rsf put there pointing at a path config_files/ no longer
# has - makes Neovim load both and error with "E5422: Conflicting configs"
# on every startup. Removed before linking so init.lua is the only one in
# place; -f is a no-op if it's already gone.
rm -f ~/.config/nvim/init.vim

cp -rsf ~/code/dotfiles/config_files/. ~
