#!/usr/bin/env bash

######################################################################
# Virtual console (boot/TTY) font size
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
######################################################################

# console-setup's own default (Fixed 8x16) is an 8x16-pixel bitmap
# font - fine at low resolutions, unreadably small on a 4K/HiDPI panel,
# since the virtual console has no DPI-scaling concept of its own (unlike
# Xorg/XFCE, which qt_scaling.sh and configure_xfce.sh handle
# separately). Terminus 32x16 is the largest stock size of the
# distro's usual HiDPI console-font recommendation, and already ships
# on disk with console-setup (no package install needed) as
# /usr/share/consolefonts/Lat15-Terminus32x16.psf.gz.
#
# console-setup.service reads /etc/default/console-setup and re-applies
# it via setupcon on every boot (before display-manager.service), so
# editing this file is what makes the change persistent - `setupcon`
# below just applies it to the already-running consoles immediately,
# same session, without waiting for a reboot.
#
# Rewrites the whole file (same other settings console-setup's package
# ships by default - only FONTFACE/FONTSIZE differ) rather than sed -i'ing
# just those two lines: sudo-rs (see lib/update_cron.sh) forbids wildcards
# anywhere in an allowlisted command's arguments except as a sole trailing
# token, and a sed replacement script built from these values would embed
# one mid-argument. A fixed `tee` destination path has no such problem.
configure_console_font() {
  local conf_file="/etc/default/console-setup"
  local rule
  rule="$(
    cat <<'EOF'
# CONFIGURATION FILE FOR SETUPCON

# Consult the console-setup(5) manual page.

ACTIVE_CONSOLES="/dev/tty[1-6]"

CHARMAP="UTF-8"

CODESET="guess"
FONTFACE="Terminus"
FONTSIZE="32x16"

VIDEOMODE=

# The following is an example how to use a braille font
# FONT='lat9w-08.psf.gz brl-8x8.psf'
EOF
  )"

  if [[ -f "$conf_file" ]] && [[ "$(cat "$conf_file")" == "$rule" ]]; then
    return 0
  fi

  echo "$rule" | sudo tee "$conf_file" >/dev/null
  sudo setupcon
}
