#!/usr/bin/env bash

################################################################################
# Install/update language runtimes via asdf
################################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh and
# update_ubuntu.sh, after util.sh and asdf_util.sh.
#
# Each function is self-contained: apt build deps, plugin add, then
# asdf_install_latest_global (asdf_util.sh) to build/install the latest
# version and set it as the global default. Same function handles
# first-time install and keeping up to date, since
# asdf_install_latest_global is a no-op when the latest version is already
# installed.
################################################################################

################################################################################
# asdf Install Ruby
################################################################################
asdf_install_ruby() {
  sudo apt-get --yes install build-essential autoconf patch libssl-dev \
    libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc libreadline-dev \
    libncurses-dev libgdbm-dev libdb-dev

  asdf_plugin_add ruby https://github.com/asdf-vm/asdf-ruby.git
  asdf_install_latest_global ruby
}

################################################################################
# asdf Install Node.js
################################################################################
asdf_install_nodejs() {
  # asdf-nodejs (via node-build) installs precompiled binaries, so nothing
  # is needed to build Node itself - unzip covers node-build's .zip
  # fallback path; build-essential/python3 are for compiling native npm
  # addons (node-gyp), e.g. bcrypt, sqlite3, sharp.
  sudo apt-get --yes install build-essential python3 unzip

  asdf_plugin_add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  asdf_install_latest_global nodejs
}

################################################################################
# asdf Install Erlang
################################################################################
# Not called directly from build/update scripts - asdf_install_elixir pulls
# this in, since Elixir needs a matching Erlang/OTP version to build
# against.
asdf_install_erlang() {
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

################################################################################
# asdf Install Elixir
################################################################################
asdf_install_elixir() {
  sudo apt-get --yes install unzip

  asdf_install_erlang

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
}

################################################################################
# asdf Install Python
################################################################################
asdf_install_python() {
  # asdf-python (via pyenv's python-build) always compiles from source.
  # List is pyenv's current recommended Ubuntu/Debian build environment,
  # including libzstd-dev - needed for 3.14+'s compression.zstd module.
  sudo apt-get --yes install make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libncurses-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libzstd-dev

  asdf_plugin_add python https://github.com/asdf-community/asdf-python.git
  asdf_install_latest_global python
}
