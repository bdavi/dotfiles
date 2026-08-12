#!/usr/bin/env bash

######################################################################
# XFCE preferences, set directly via xfconf-query
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after util.sh.
#
# XFCE config files under ~/.config/xfce4 used to be symlinked in from
# config_files/ (see install_dotfiles.sh), but xfconfd and friends save
# via write-temp-then-rename, which replaces a symlink at that path with a
# brand new regular file - so the very first save after linking silently
# severs the link back to this repo. These functions set the same
# preferences directly through xfconf-query instead, which is what
# actually persists.
#
# Each function is idempotent - safe to re-run any time, same as the
# asdf_* install functions. Note -n is create-if-missing but still
# overwrites the value when the property already exists (verified
# empirically) - so re-runs reassert every value here, and anything
# host-specific has to win by running *after* the generic functions
# (see configure_xfce_hidpi_host_overrides).
######################################################################

# GTK theme and icon theme - checked against Xubuntu's shipped defaults
# (/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml: Greybird /
# elementary-xfce-dark) to confirm both actually differ from stock.
#
# HiDPI scaling (/Xft/DPI here, QT_SCALE_FACTOR in qt_scaling.sh for Qt
# apps) was tried at 1.75x and reverted - too large in practice
# (KeePassXC especially). Both are explicitly reset back to Xubuntu's
# shipped defaults rather than left stale at the old override, same as
# the Gdk/WindowScalingFactor reset below (an even earlier, 2x integer
# attempt at the same goal).
#
# The xsettings channel also carries a live cursor theme/size and
# icon-size override beyond these - out of scope here (this pass only
# covers xfwm4/panel/power-manager), flagging for a follow-up pass.
configure_xfce_theme() {
  xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "Greybird-dark"
  xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "elementary-xfce"
  xfconf-query -c xsettings -p /Xft/DPI -r 2>/dev/null || true
  xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -r 2>/dev/null || true
}

# Terminal color scheme (dark navy background) and font - the rest of
# xfce4-terminal.xml is default.
configure_xfce_terminal() {
  xfconf-query -c xfce4-terminal -p /color-foreground -n -t string -s "#b7b7b7"
  xfconf-query -c xfce4-terminal -p /color-background -n -t string -s "#131926"
  xfconf-query -c xfce4-terminal -p /color-cursor -n -t string -s "#0f4999"
  xfconf-query -c xfce4-terminal -p /color-selection -n -t string -s "#163b59"
  xfconf-query -c xfce4-terminal -p /color-selection-use-default -n -t bool -s false
  xfconf-query -c xfce4-terminal -p /color-bold -n -t string -s "#ffffff"
  xfconf-query -c xfce4-terminal -p /color-bold-use-default -n -t bool -s false
  xfconf-query -c xfce4-terminal -p /color-palette -n -t string \
    -s "#000000;#aa0000;#44aa44;#aa5500;#0039aa;#aa22aa;#1a92aa;#aaaaaa;#777777;#ff8787;#4ce64c;#ded82c;#295fcc;#cc58cc;#4ccce6;#ffffff"
  xfconf-query -c xfce4-terminal -p /font-name -n -t string -s "JetBrainsMono Nerd Font Mono 10"
  xfconf-query -c xfce4-terminal -p /tab-activity-color -n -t string -s "#0f4999"
}

# Power button/lid/blanking behavior. Xubuntu only ships a default for
# power-button-action (see the xsettings comment above for how that
# default file is found) - it's absent here, so left untouched. Everything
# below has no shipped default at all, meaning it's unset until explicitly
# written - confirms these are real overrides, not schema noise.
configure_xfce_power_manager() {
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -n -t bool -s true
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -n -t uint -s 60
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/show-tray-icon -n -t bool -s false
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/brightness-switch-restore-on-exit -n -t int -s 1
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/brightness-switch -n -t int -s 0
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-ac -n -t uint -s 1
}

# Single top panel on the primary display: thin (24px), full-width,
# autohide off, 10 plugins in order - whiskermenu, separator, tasklist,
# expanding separator, workspace switcher, systray, notifications, power
# manager, pulseaudio, clock. Vanilla xfce4 (the Budgie box's alternative
# session) also ships a second bottom dock panel that Xubuntu doesn't -
# /panels below drops it, and its stale panel-2 subtree gets cleared.
# whiskermenu's "recent" list and systray's "known-items" are usage-history
# caches, not settings - deliberately not reproduced here, they'll just
# repopulate on use.
#
# Restarts the panel at the end so plugins are actually instantiated from
# these properties (xfce4-panel only reads /plugins/plugin-N to build
# panel-1's contents on startup/restart) - skipped if the panel isn't
# running yet, e.g. during initial box setup before a desktop session exists.
#
# plugin-ids below and the per-plugin-N blocks are two separate lists
# that have to stay in sync by hand - adding/reordering a plugin means
# updating both.
configure_xfce_panel() {
  xfconf-query -c xfce4-panel -p /panels -n -a -t int -s 1
  xfconf-query -c xfce4-panel -p /panels/panel-2 -r -R 2>/dev/null || true

  xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s "p=6;x=0;y=0"
  # "Primary" tracks whichever monitor is flagged primary in xrandr, so
  # the panel follows docking changes without pinning a connector name.
  xfconf-query -c xfce4-panel -p /panels/panel-1/output-name -n -t string -s Primary
  xfconf-query -c xfce4-panel -p /panels/panel-1/length -n -t uint -s 100
  xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true
  xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n \
    -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 -t int -s 10 -t int -s 5 -t int -s 6 -t int -s 7 -t int -s 8 -t int -s 9
  xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -n -t uint -s 0
  xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t uint -s 24
  xfconf-query -c xfce4-panel -p /panels/panel-1/length-adjust -n -t bool -s true
  xfconf-query -c xfce4-panel -p /panels/panel-1/span-monitors -n -t bool -s false
  xfconf-query -c xfce4-panel -p /panels/panel-1/mode -n -t uint -s 0
  xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -n -t uint -s 0

  # plugin-1: whiskermenu (app menu)
  xfconf-query -c xfce4-panel -p /plugins/plugin-1 -n -t string -s whiskermenu
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/favorites -n \
    -t string -s xfce4-web-browser.desktop \
    -t string -s xfce4-mail-reader.desktop \
    -t string -s xfce4-file-manager.desktop \
    -t string -s xfce4-terminal-emulator.desktop \
    -t string -s xfhelp4.desktop
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-command-suspend -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-command-shutdown -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-command-restart -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-command-logoutuser -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/profile-shape -n -t int -s 1
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-icon -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-title -n -t bool -s false
  xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-single-row -n -t bool -s false

  # plugin-2: fixed separator, ahead of the tasklist
  xfconf-query -c xfce4-panel -p /plugins/plugin-2 -n -t string -s separator
  xfconf-query -c xfce4-panel -p /plugins/plugin-2/style -n -t uint -s 0
  xfconf-query -c xfce4-panel -p /plugins/plugin-2/expand -n -t bool -s false

  # plugin-3: window tasklist
  xfconf-query -c xfce4-panel -p /plugins/plugin-3 -n -t string -s tasklist
  xfconf-query -c xfce4-panel -p /plugins/plugin-3/show-handle -n -t bool -s false
  xfconf-query -c xfce4-panel -p /plugins/plugin-3/flat-buttons -n -t bool -s true

  # plugin-4: expanding separator, pushes everything after it to the right
  xfconf-query -c xfce4-panel -p /plugins/plugin-4 -n -t string -s separator
  xfconf-query -c xfce4-panel -p /plugins/plugin-4/style -n -t uint -s 0
  xfconf-query -c xfce4-panel -p /plugins/plugin-4/expand -n -t bool -s true

  # plugin-10: workspace switcher, just left of the system tray/network icon
  xfconf-query -c xfce4-panel -p /plugins/plugin-10 -n -t string -s pager

  # plugin-5: system tray
  xfconf-query -c xfce4-panel -p /plugins/plugin-5 -n -t string -s systray
  xfconf-query -c xfce4-panel -p /plugins/plugin-5/menu-is-primary -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-5/show-frame -n -t bool -s false
  xfconf-query -c xfce4-panel -p /plugins/plugin-5/square-icons -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-5/size-max -n -t uint -s 22
  xfconf-query -c xfce4-panel -p /plugins/plugin-5/symbolic-icons -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-5/icon-size -n -t int -s 0

  # plugin-6/7: notification area and power manager icons, no config of their own
  xfconf-query -c xfce4-panel -p /plugins/plugin-6 -n -t string -s notification-plugin
  xfconf-query -c xfce4-panel -p /plugins/plugin-7 -n -t string -s power-manager-plugin

  # plugin-8: pulseaudio volume control
  xfconf-query -c xfce4-panel -p /plugins/plugin-8 -n -t string -s pulseaudio
  xfconf-query -c xfce4-panel -p /plugins/plugin-8/enable-keyboard-shortcuts -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-8/enable-mpris -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-8/enable-wnck -n -t bool -s true
  xfconf-query -c xfce4-panel -p /plugins/plugin-8/known-players -n -t string -s "parole;org.gnome.Rhythmbox3"
  xfconf-query -c xfce4-panel -p /plugins/plugin-8/mixer-command -n -t string -s pavucontrol
  xfconf-query -c xfce4-panel -p /plugins/plugin-8/persistent-players -n -t string -s "parole;org.gnome.Rhythmbox3"
  xfconf-query -c xfce4-panel -p /plugins/plugin-8/show-notifications -n -t bool -s true

  # plugin-9: clock, e.g. "Sun, 19 Jul, 10:18pm"
  xfconf-query -c xfce4-panel -p /plugins/plugin-9 -n -t string -s clock
  xfconf-query -c xfce4-panel -p /plugins/plugin-9/digital-format -n -t string -s "%a, %-d %b, %-I:%M%P"
  xfconf-query -c xfce4-panel -p /plugins/plugin-9/digital-time-format -n -t string -s "%a, %-d %b, %-I:%M%P"
  xfconf-query -c xfce4-panel -p /plugins/plugin-9/digital-layout -n -t uint -s 3

  xfconf-query -c xfce4-panel -p /configver -n -t int -s 2

  pgrep -x xfce4-panel >/dev/null && xfce4-panel -r
}

# Custom keyboard shortcuts. Same "dialog resaves everything" pattern as
# xfwm4.xml below - diffing xfce4-keyboard-shortcuts' live custom/ tree
# against its default/ tree (xfconf-query -c xfce4-keyboard-shortcuts -l -v)
# turned up exactly one real difference: this binding, added on top of the
# existing default shortcuts rather than replacing any of them.
#
# Also clears the xfwm4 <Shift>Down -> tile_down_key binding: it steals
# plain Shift+Down from apps (e.g. text selection) to tile the focused
# window instead. -r removes the override outright rather than -n/-s'ing
# a replacement, since there's no single-key binding worth keeping there;
# it's harmless to re-run if the property is already gone.
#
# <Super>Left/Right -> tile_left_key/tile_right_key: half-screen tiling.
# These already exist as xfwm4 defaults, but are re-asserted here because
# of a real bug hit in practice: an earlier manual re-bind (via the
# Keyboard settings dialog, likely triggered by NumLock being on at the
# time) left a second custom binding, <Super>KP_Right -> tile_right_key,
# alongside <Super>Right -> tile_right_key. Two custom key combos mapped
# to the same action name breaks xfwm4's grab registration - it silently
# failed to grab the plain arrow-key combo at all, so <Super>Right passed
# straight through to whatever window had focus instead of tiling it,
# while <Super>Left (which had no such duplicate) kept working. Confirmed
# via xev that ungrabbed keys are delivered to the focused client rather
# than intercepted, and that removing the duplicate + restarting xfwm4
# fixed it. The -r calls below clear that duplicate (and its Left/Down/Up
# counterparts, in case the same NumLock accident recurs) before -n/-s
# (re)asserts the single arrow-key binding each is meant to have.
#
# Restarts xfwm4 at the end (same pattern as the panel restart in
# configure_xfce_panel) so a fix here - or a fresh custom/KP_* duplicate
# this script just cleared - takes effect immediately instead of needing
# a logout. Skipped if xfwm4 isn't running yet, e.g. during initial box
# setup before a desktop session exists.
configure_xfce_keyboard_shortcuts() {
  xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -n -t string -s "xfce4-popup-whiskermenu"
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Shift>Down" -r 2>/dev/null || true

  for kp in KP_Left KP_Right KP_Up KP_Down; do
    xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>$kp" -r 2>/dev/null || true
  done
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Left" -n -t string -s "tile_left_key"
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Right" -n -t string -s "tile_right_key"

  # <Super>Up -> maximize (toggle). The custom tree ships <Alt>F10 ->
  # maximize_window_key; that's cleared first because it would be a
  # second custom binding on the same action - the exact duplicate-action
  # grab bug described above, which would leave <Super>Up silently
  # ungrabbed.
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Alt>F10" -r 2>/dev/null || true
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Up" -n -t string -s "maximize_window_key"

  pgrep -x xfwm4 >/dev/null && xfwm4 --replace &
}

# Bare Super tap -> whisker menu, without breaking held-Super combos
# (the tiling/maximize bindings above). Binding Super_L directly in
# xfce4-keyboard-shortcuts doesn't work: the grab fires on key *press*,
# so every Super+arrow combo popped the menu, whose keyboard grab then
# swallowed the arrow key - tested and reverted. Instead xcape
# (installed in build_ubuntu.sh) injects a keystroke only on a *tap* -
# Super pressed and released with nothing else in between. The injected
# key is XF86Launch5, a phantom keysym no physical keyboard emits, so
# it can't collide with anything (Ctrl+Escape, the whiskermenu FAQ's
# suggestion, is already xfdesktop --menu). <Super>space (set above)
# stays as a fallback for the same popup.
#
# The autostart entry is OnlyShowIn=XFCE so xcape doesn't hijack the
# Super key under the Budgie session on the work box. Written as a
# plain file, not a config_files/ symlink, to match how this script
# owns its config (see header).
configure_xfce_super_whiskermenu() {
  xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/XF86Launch5" -n -t string -s "xfce4-popup-whiskermenu"

  mkdir -p ~/.config/autostart
  cat > ~/.config/autostart/xcape-whisker.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=xcape (Super tap -> Whisker Menu)
Comment=Tap of bare Super injects XF86Launch5, which xfce4-keyboard-shortcuts binds to xfce4-popup-whiskermenu. Held Super combos (tiling/maximize) are unaffected.
Exec=xcape -e 'Super_L=XF86Launch5'
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
EOF

  # take effect now rather than at next login; xcape daemonizes itself
  pgrep -u "$USER" -x xcape >/dev/null || xcape -e 'Super_L=XF86Launch5'
}

# Number of virtual desktops - pairs with the workspace switcher plugin
# added in configure_xfce_panel. Workspace names aren't set explicitly;
# xfwm4 auto-generates "Workspace N" for any workspace without a stored
# name.
configure_xfce_workspaces() {
  xfconf-query -c xfwm4 -p /general/workspace_count -n -t int -s 2
}

# Per-host overrides for the work laptop's 32" 4K Dell, which at stock
# sizes is squint territory. Whole-UI scaling was ruled out there:
# fractional per-monitor scale is broken on NVIDIA PRIME (the image
# scales but the input map doesn't, so clicks land offset from what's
# drawn), and 2x (GDK window scaling / 1.75x DPI) was tried and
# reverted as too large - see configure_xfce_theme. What works: 1.25x
# fonts via Xft DPI - which Qt apps also pick up through xrdb, unlike
# the rest of xsettings (they ignore /Gtk/FontName entirely, cf.
# qt_scaling.sh) - plus a taller panel with icon size 0 (= track the
# row height instead of pinning 16px). Hostname-gated: the other boxes
# drive 1080p monitors where the stock sizes are fine.
#
# Must run after configure_xfce_theme (which resets /Xft/DPI) and
# configure_xfce_panel (which asserts the stock 24px size) - -n still
# overwrites existing values on re-run (see header), so last write wins.
configure_xfce_hidpi_host_overrides() {
  [ "$(hostname)" = "REM-BDAVIES-LT3" ] || return 0
  xfconf-query -c xsettings -p /Xft/DPI -n -t int -s 120
  xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t uint -s 36
  xfconf-query -c xfce4-panel -p /panels/panel-1/icon-size -n -t int -s 0
}

# xfwm4 --replace in configure_xfce_keyboard_shortcuts hands window
# management off to a fresh xfwm4 instance - this has repeatedly left the
# top panel hidden behind other windows afterward, since the new instance
# doesn't reliably pick up the panel's existing reserve-space/stacking
# hints. Restarting the panel again here, as the last step of the whole
# XFCE pass (after every function that can perturb it, not just the
# keyboard-shortcuts one), reasserts those hints and guarantees it's
# visible regardless of what ran before it - skipped if the panel isn't
# running yet, e.g. during initial box setup before a desktop session
# exists.
configure_xfce_ensure_panel_visible() {
  pgrep -x xfce4-panel >/dev/null && xfce4-panel -r
}

# xfwm4.xml otherwise deliberately NOT covered here (workspace_count
# above is the one confirmed exception). Unlike the channels above, xfwm4
# has no shipped Xubuntu default file to diff against, and its tracked
# xml dumps a real value for nearly every window-manager property (~50 of
# them) - a known effect of opening the Window Manager Tweaks dialog,
# which resaves the whole resolved property set, defaults included.
# Skimming the rest of the list against remembered Xfce defaults, none of
# it looks like a deliberate customization (e.g. double_click_action is
# "maximize" and easy_click is "Alt", both stock) - so there's nothing
# else here to confidently script. Happy to add specific properties if
# there's something in there you know you actually changed.
