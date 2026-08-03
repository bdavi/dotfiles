#!/usr/bin/env bash

######################################################################
# Qt HiDPI scaling (env var, since Qt ignores xsettings entirely)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
#
# Qt apps (KeePassXC, SpeedCrunch, ...) don't read the xsettings
# /Xft/DPI bump set in configure_xfce_theme (configure_xfce.sh) - Qt has
# its own, separate HiDPI mechanism. QT_SCALE_FACTOR (a fixed float,
# rather than QT_AUTO_SCREEN_SCALE_FACTOR's auto-detection from the
# monitor's reported physical size) keeps Qt apps locked to the same
# 1.75x ratio chosen for /Xft/DPI.
#
# /etc/environment is read by PAM at login, before the desktop session
# starts, so every Qt app in the session inherits it - unlike the
# xfconf settings above, this only takes effect on the next login, not
# immediately. Idempotent via the grep guard - safe to re-run.
######################################################################
configure_qt_scale_factor() {
  local line="QT_SCALE_FACTOR=1.75"
  grep -qxF "$line" /etc/environment 2>/dev/null || echo "$line" | sudo tee -a /etc/environment >/dev/null
}
