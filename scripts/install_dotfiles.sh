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

# Wire up the publish guard: a PreToolUse hook that forces an approval prompt
# for git commit, git push, gh pr create/edit and gh repo create, and hard-
# blocks gh pr merge. The script itself installs as a symlink with everything
# else under config_files/; this merges its registration into settings.json.
#
# Merged rather than symlinked because Claude Code writes to that file itself
# (/model, /config), so linking it would put personal state in this public repo
# and let the next install clobber it. Merging touches only the guard's keys and
# is idempotent - the same shape comoto-dotfiles/install.sh uses for
# permissions.additionalDirectories.
#
# The hook is the mechanism, not the permission rules: ask rules were verified
# NOT to fire in auto mode (2026-09-14), with the hook disabled and a matching
# git commit running unprompted. They are kept only as a backstop for other
# permission modes.
install_publish_guard() {
  local settings=~/.claude/settings.json tmp
  command -v jq >/dev/null || { echo "jq missing - publish guard NOT installed" >&2; return 1; }
  mkdir -p ~/.claude
  [ -f "$settings" ] || echo '{}' > "$settings"
  tmp="$(mktemp)"
  jq '
    def guard_entry:
      { matcher: "Bash",
        hooks: [
          { type: "command", if: "Bash(git *)",
            command: "~/.claude/hooks/guard-git-write.sh",
            timeout: 10, statusMessage: "Checking publish authorization" },
          { type: "command", if: "Bash(gh *)",
            command: "~/.claude/hooks/guard-git-write.sh",
            timeout: 10, statusMessage: "Checking publish authorization" }
        ] };
    .hooks.PreToolUse =
      ([ (.hooks.PreToolUse // [])[]
         | select([.hooks[]?.command // ""] | map(test("guard-git-write")) | any | not) ]
       + [guard_entry])
    | .permissions.ask =
        (((.permissions.ask // []) + [
          "Bash(git commit *)", "Bash(git push *)",
          "Bash(git * commit *)", "Bash(git * push *)",
          "Bash(gh pr create *)", "Bash(gh pr edit *)", "Bash(gh repo create *)"
        ]) | unique)
    | .permissions.deny =
        (((.permissions.deny // []) + ["Bash(gh pr merge *)"]) | unique)
  ' "$settings" > "$tmp" && mv "$tmp" "$settings" \
    && echo "publish guard registered in $settings"
}

install_publish_guard

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
