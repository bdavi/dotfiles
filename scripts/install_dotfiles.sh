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

# ~/.claude/CLAUDE.md imports ~/AGENTS.comoto.md, which only exists once the
# private work overlay is installed. Create an empty stub so the import
# resolves on a personal machine instead of dangling. Never overwrites a real
# one: the overlay's installer replaces this with a symlink into its repo.
[ -e ~/AGENTS.comoto.md ] || : > ~/AGENTS.comoto.md

# The work overlay (bdavi/comoto-dotfiles, private) carries everything that
# names the employer - shell config, worktree tooling, work agent instructions
# and skills. Nothing here depends on it; it's additive. See
# docs/work-overlay.md.
WORK_REPO=~/code/comoto-dotfiles

if [ -d "$WORK_REPO" ]; then
  read -r -p "Work overlay found at $WORK_REPO. Install it too? [Y/n] " reply
  case "$reply" in
    [Nn]*) echo "Skipped." ;;
    *) "$WORK_REPO/install.sh" ;;
  esac
elif [ -t 0 ]; then
  read -r -p "Clone and install the private work overlay (bdavi/comoto-dotfiles)? [y/N] " reply
  case "$reply" in
    [Yy]*)
      git clone git@github.com:bdavi/comoto-dotfiles.git "$WORK_REPO" \
        && "$WORK_REPO/install.sh"
      ;;
    *) echo "Skipped. Run this script again later to install it." ;;
  esac
fi
