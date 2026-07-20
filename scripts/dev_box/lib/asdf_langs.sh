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
