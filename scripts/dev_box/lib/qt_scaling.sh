#!/usr/bin/env bash

######################################################################
# Qt HiDPI scaling (env var, since Qt ignores xsettings entirely)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
#
# Was QT_SCALE_FACTOR=1.75, matching a since-reverted 1.75x /Xft/DPI
# bump (configure_xfce_theme, configure_xfce.sh) - too large in practice
# (KeePassXC especially). Removes the line from /etc/environment if
# present rather than leaving it stale, same as the DPI/window-scaling
# resets above.
#
# /etc/environment is read by PAM at login, before the desktop session
# starts - unlike the xfconf settings above, this only takes effect on
# the next login, not immediately. Idempotent - safe to re-run.
######################################################################
configure_qt_scale_factor() {
  sudo sed -i '/^QT_SCALE_FACTOR=/d' /etc/environment
}
