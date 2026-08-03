#!/usr/bin/env bash

######################################################################
# zizmor (via pip)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh and asdf_langs.sh (needs asdf's python/pip on PATH already).
######################################################################

# Installs (or upgrades to) the latest zizmor via pip - --upgrade so
# reruns pick up new releases instead of only installing once.
install_latest_zizmor() {
  pip install --upgrade zizmor
}
