#!/usr/bin/env bash

######################################################################
# Install/update language runtimes via asdf
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh
# and asdf_util.sh.
#
# Each asdf_install_* function is self-contained: apt build deps, plugin
# add, then asdf_install_latest_global (asdf_util.sh) to build/install the
# latest version and set it as the global default. Same function handles
# first-time install and keeping up to date, since
# asdf_install_latest_global is a no-op when the latest version is already
# installed.
#
# Each has a matching asdf_cleanup_* function (asdf_cleanup_old_versions,
# asdf_util.sh) that removes old installed versions once a new one is in,
# keeping only the latest (plus anything listed in
# asdf_pinned_versions.conf) so compiled versions don't pile up on disk.
######################################################################

######################################################################
# asdf Install Ruby
######################################################################
asdf_install_latest_ruby() {
  sudo apt-get --yes install build-essential autoconf patch libssl-dev \
    libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc libreadline-dev \
    libncurses-dev libgdbm-dev libdb-dev

  asdf_plugin_add ruby https://github.com/asdf-vm/asdf-ruby.git
  asdf_install_latest_global ruby
}

asdf_cleanup_ruby() {
  asdf_cleanup_old_versions ruby
}

######################################################################
# asdf Install Node.js
######################################################################
asdf_install_latest_nodejs() {
  # asdf-nodejs (via node-build) installs precompiled binaries, so nothing
  # is needed to build Node itself - unzip covers node-build's .zip
  # fallback path; build-essential/python3 are for compiling native npm
  # addons (node-gyp), e.g. bcrypt, sqlite3, sharp.
  sudo apt-get --yes install build-essential python3 unzip

  asdf_plugin_add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  asdf_install_latest_global nodejs
}

asdf_cleanup_nodejs() {
  asdf_cleanup_old_versions nodejs
}

######################################################################
# asdf Install Erlang
######################################################################
# Not called directly from build/update scripts -
# asdf_install_latest_elixir pulls this in, since Elixir needs a matching
# Erlang/OTP version to build against.
asdf_install_latest_erlang() {
  # perl and libssl-dev are required (not optional) per OTP's own
  # HOWTO/INSTALL.md - libssl-dev in particular builds `crypto`, which
  # `ssl`/`ssh`/`public_key` all depend on; without it those apps get
  # silently skipped and nothing needing HTTPS works (Mix, Hex, Phoenix...).
  sudo apt-get --yes install build-essential autoconf m4 perl libssl-dev \
    libncurses-dev libwxgtk3.2-dev libwxgtk-webview3.2-dev libgl1-mesa-dev \
    libglu1-mesa-dev libpng-dev unixodbc-dev

  asdf_plugin_add erlang https://github.com/asdf-vm/asdf-erlang.git

  # Skips the `jinterface` app (Java/Erlang interop, needs a JDK) - not
  # needed for Ruby/Node/Elixir work. kerl doesn't build the HTML/PDF
  # reference docs by default either way (that needs KERL_BUILD_DOCS=yes,
  # which we're not setting), so this isn't what's keeping fop/openjdk out.
  KERL_CONFIGURE_OPTIONS="--without-javac" asdf_install_latest_global erlang
}

# Not called directly from build/update scripts - asdf_cleanup_elixir
# pulls this in, mirroring asdf_install_latest_erlang.
asdf_cleanup_erlang() {
  asdf_cleanup_old_versions erlang
}

######################################################################
# asdf Install Elixir
######################################################################
asdf_install_latest_elixir() {
  sudo apt-get --yes install unzip

  asdf_install_latest_erlang

  asdf_plugin_add elixir https://github.com/asdf-vm/asdf-elixir.git

  # Elixir ships precompiled per supported OTP major - without the
  # -otp-<major> suffix, asdf-elixir installs the build made against the
  # *oldest* OTP that release still supports, not the Erlang we just
  # installed. Fall back to that oldest-OTP build if a precompiled variant
  # for our OTP major doesn't exist yet (e.g. Erlang just cut a new major
  # that Elixir hasn't published a build against).
  local erlang_major elixir_latest elixir_version
  erlang_major="$(asdf latest erlang | cut -d. -f1)"
  elixir_latest="$(asdf latest elixir)"
  elixir_version="${elixir_latest}-otp-${erlang_major}"

  if ! asdf install elixir "$elixir_version"; then
    echo "No elixir build for OTP ${erlang_major}, falling back to ${elixir_latest}" >&2
    elixir_version="$elixir_latest"
    asdf install elixir "$elixir_version"
  fi

  asdf set --home elixir "$elixir_version"

  asdf_install_pinned_versions elixir
}

asdf_cleanup_elixir() {
  asdf_cleanup_erlang
  asdf_cleanup_old_versions elixir
}

######################################################################
# asdf Install Python
######################################################################
asdf_install_latest_python() {
  # asdf-python (via pyenv's python-build) always compiles from source.
  # List is pyenv's current recommended Ubuntu/Debian build environment,
  # including libzstd-dev - needed for 3.14+'s compression.zstd module.
  sudo apt-get --yes install make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libncurses-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libzstd-dev

  asdf_plugin_add python https://github.com/asdf-community/asdf-python.git
  asdf_install_latest_global python
}

asdf_cleanup_python() {
  asdf_cleanup_old_versions python
}

######################################################################
# asdf Install Go
######################################################################
asdf_install_latest_golang() {
  # asdf-golang installs precompiled binaries, so no build deps are needed.
  asdf_plugin_add golang https://github.com/asdf-community/asdf-golang.git
  asdf_install_latest_global golang
}

asdf_cleanup_golang() {
  asdf_cleanup_old_versions golang
}

######################################################################
# asdf Install Rust
######################################################################
asdf_install_latest_rust() {
  # asdf-rust installs official precompiled toolchains (rustc + cargo), so
  # no build deps are needed. Added for building the patched herdr-mirror
  # plugin from source (install_herdr_mirror_plugin, lib/herdr.sh) while
  # upstream PR nikok6/herdr-mirror#27 is unmerged; kept unconditionally
  # since a Rust toolchain is generally useful. Note ruby's build deps
  # above apt-install rustc (for YJIT) - the asdf shim wins in PATH, so
  # that older system rustc doesn't interfere.
  asdf_plugin_add rust https://github.com/asdf-community/asdf-rust.git
  asdf_install_latest_global rust
}

asdf_cleanup_rust() {
  asdf_cleanup_old_versions rust
}

######################################################################
# asdf Install pnpm
######################################################################
asdf_install_latest_pnpm() {
  # asdf-pnpm installs precompiled binaries, so no build deps are needed.
  asdf_plugin_add pnpm https://github.com/jonathanmorley/asdf-pnpm.git
  asdf_install_latest_global pnpm
}

asdf_cleanup_pnpm() {
  asdf_cleanup_old_versions pnpm
}

######################################################################
# asdf Install lefthook
######################################################################
asdf_install_latest_lefthook() {
  # asdf-lefthook installs precompiled binaries, so no build deps are needed.
  asdf_plugin_add lefthook https://github.com/jtzero/asdf-lefthook.git
  asdf_install_latest_global lefthook
}

asdf_cleanup_lefthook() {
  asdf_cleanup_old_versions lefthook
}
