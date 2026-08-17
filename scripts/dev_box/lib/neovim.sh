#!/usr/bin/env bash

######################################################################
# Neovim
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh and install_dotfiles.sh (config_files/.config/nvim/init.lua
# needs to already be symlinked into place).
#
# init.lua bootstraps lazy.nvim itself on first launch, so there's no
# separate plugin-manager install step here - just driving Neovim
# headlessly to force everything lazy.nvim manages (plugins, Treesitter
# parsers) to actually finish installing, rather than racing background
# jobs that a plain `Lazy sync` + `+qa` would kill mid-install.
######################################################################

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

# Ubuntu's apt package lags plugins' minimum-version requirements badly -
# noble's "neovim" is stuck at 0.9.5, but current plugins (e.g.
# snacks.nvim's `nvim_get_hl(..., { create = false })`) call APIs only
# added in 0.10+. Downloads the official release tarball straight to
# ~/.local/bin instead, same approach lib/security_scanners.sh and
# install_asdf (asdf_util.sh) use for tools apt can't keep current. The
# tarball is a full runtime tree, not a standalone binary - `nvim` looks
# up its runtime files relative to its own path - so it's extracted whole
# rather than just lifting the binary out, then symlinked into
# ~/.local/bin so it shadows apt's copy (~/.local/bin precedes /usr/bin
# on PATH). Not removing any existing apt-installed neovim - harmless
# leftover once shadowed, and removing packages out from under a script
# that didn't install them is riskier than leaving them be.
install_neovim_binary() {
  local latest
  latest="$(github_latest_release neovim/neovim 0)"

  if [[ -z "$latest" ]]; then
    echo "Could not resolve latest neovim v0 release" >&2
    exit 1
  fi

  local installed=""
  if [[ -x ~/.local/bin/nvim ]]; then
    installed="$(~/.local/bin/nvim --version | head -n1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')"
  fi

  if [[ "$installed" == "$latest" ]]; then
    echo "neovim $latest already installed"
    return 0
  fi

  # Neovim's own release asset naming (x86_64/arm64) doesn't match
  # release_arch's Go-style amd64/arm64, so this maps uname -m directly
  # rather than reusing that helper.
  local nvim_arch
  case "$(uname -m)" in
    x86_64) nvim_arch="x86_64" ;;
    aarch64) nvim_arch="arm64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac

  local install_dir="$HOME/.local/share/nvim-linux-${nvim_arch}"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  curl -fsSL \
    "https://github.com/neovim/neovim/releases/download/${latest}/nvim-linux-${nvim_arch}.tar.gz" \
    -o "$tmp/nvim.tar.gz"

  rm -rf "$install_dir"
  mkdir -p "$install_dir"
  tar -xzf "$tmp/nvim.tar.gz" -C "$install_dir" --strip-components=1

  mkdir -p ~/.local/bin
  ln -sf "$install_dir/bin/nvim" ~/.local/bin/nvim

  echo "Installed neovim $latest to $install_dir (symlinked at ~/.local/bin/nvim, was: ${installed:-not installed})"
}

install_neovim() {
  sudo apt-get --yes install \
    build-essential \
    fzf \
    ripgrep \
    tree-sitter-cli \
    unzip \
    xclip

  install_neovim_binary

  install_nerd_font

  # Installs/updates every plugin lazy.nvim manages.
  nvim --headless "+Lazy! sync" +qa

  # nvim-treesitter's `main` branch (config_files/.config/nvim/init.lua)
  # installs its own parsers via an async `install()` job as part of
  # loading during the "Lazy! sync" run above, but that job can still be
  # mid-compile when +qa exits. `main` also dropped `:TSUpdateSync` (the
  # old `master`-branch blocking command), so instead this re-issues the
  # same install call and blocks on it directly - a no-op wait for
  # anything already compiled, a real wait for anything still in flight.
  # Keep this list in sync with the `parsers` list in init.lua.
  nvim --headless -c "lua require('nvim-treesitter').install({
    'bash', 'css', 'elixir', 'embedded_template', 'erlang', 'go',
    'html', 'javascript', 'json', 'lua', 'markdown', 'markdown_inline',
    'perl', 'python', 'query', 'ruby', 'tsx', 'typescript', 'vim',
    'vimdoc', 'yaml',
  }):wait(300000)" +qa
}
