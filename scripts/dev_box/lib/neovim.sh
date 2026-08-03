#!/usr/bin/env bash

######################################################################
# Neovim
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh and install_dotfiles.sh (config_files/.config/nvim/init.lua
# needs to already be symlinked into place) and after the "Languages
# (via asdf)" section - ruby_lsp/elixirls/ts_ls/css-lsp need
# Ruby/Elixir+Erlang/Node already on PATH before Mason can install them.
#
# init.lua bootstraps lazy.nvim itself on first launch, so there's no
# separate plugin-manager install step here - just driving Neovim
# headlessly to force everything lazy.nvim manages (plugins, Treesitter
# parsers, Mason LSP servers) to actually finish installing, rather than
# racing background jobs that a plain `Lazy sync` + `+qa` would kill
# mid-install.
#
# The Mason step in particular needs to be explicit: mason-lspconfig's
# `ensure_installed` (config_files/.config/nvim/init.lua) silently no-ops
# under `nvim --headless` (mason-core.platform.is_headless - true
# whenever no UI is attached, which is always the case here), since it's
# designed assuming a human is present for an interactive first run. An
# unattended box would otherwise never get the LSP servers installed at
# all, with no error to point at. This drives the same installs directly
# via mason-registry instead of relying on that plugin's own trigger.
######################################################################

# Keep in sync with the ensure_installed list in
# config_files/.config/nvim/init.lua (lspconfig server names there vs.
# Mason package names here - mason-lspconfig translates between the two,
# e.g. ruby_lsp <-> ruby-lsp).
NEOVIM_MASON_PACKAGES=(elixir-ls css-lsp typescript-language-server ruby-lsp)

# lualine's default branch/diagnostic icons, blink.cmp's completion kind
# icons, and fzf-lua/oil.nvim's file icons (via nvim-web-devicons) are all
# Nerd Font glyphs (private-use-area codepoints) -- without this installed
# they render as blank boxes, not just plain text. Only installs the font
# itself; selecting it as your terminal emulator's font is a separate,
# terminal-specific manual step this can't do for you.
install_nerd_font() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  if compgen -G "$font_dir/*.ttf" >/dev/null; then
    return 0
  fi

  local version
  version="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
    | grep -o '"tag_name": *"[^"]*"' | sed -E 's/.*"([^"]+)"$/\1/')"

  local tmp_zip
  tmp_zip="$(mktemp --suffix=.zip)"
  trap 'rm -f "$tmp_zip"' RETURN
  curl -fLo "$tmp_zip" \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip"

  mkdir -p "$font_dir"
  unzip -o -q "$tmp_zip" -d "$font_dir"

  fc-cache -f "$font_dir"
}

install_neovim() {
  sudo apt-get --yes install \
    build-essential \
    fzf \
    neovim \
    ripgrep \
    tree-sitter-cli \
    unzip \
    xclip

  install_nerd_font

  # Installs/updates every plugin lazy.nvim manages.
  nvim --headless "+Lazy! sync" +qa

  # Blocks until every configured parser finishes compiling - unlike
  # ensure_installed's async auto_install, which +qa can cut off mid-job.
  nvim --headless "+TSUpdateSync" +qa

  # See the file header: mason-lspconfig's own ensure_installed is a
  # deliberate no-op under headless, so this drives the installs itself
  # and waits for them to actually finish. A real Lua file rather than a
  # `-c` one-liner - Neovim's ex-command line doesn't parse a `lua <<EOF`
  # heredoc the way a shell does, so passing multi-line Lua through `-c`
  # directly fails with a syntax error.
  local mason_wait_script
  mason_wait_script="$(mktemp --suffix=.lua)"
  trap 'rm -f "$mason_wait_script"' RETURN

  {
    printf "local names = {\n"
    printf '  "%s",\n' "${NEOVIM_MASON_PACKAGES[@]}"
    printf "}\n"
    cat <<'LUA'
local registry = require("mason-registry")
for _, name in ipairs(names) do
  local pkg = registry.get_package(name)
  if not pkg:is_installed() and not pkg:is_installing() then
    pkg:install()
  end
end
local ok = vim.wait(600000, function()
  for _, name in ipairs(names) do
    if not registry.get_package(name):is_installed() then
      return false
    end
  end
  return true
end, 1000)
if not ok then
  error("Timed out waiting for Mason to install: " .. table.concat(names, ", "))
end
LUA
  } >"$mason_wait_script"

  nvim --headless "+luafile $mason_wait_script" +qa
}
