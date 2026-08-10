#!/usr/bin/env bash

######################################################################
# Budgie panel on the external monitor (Wayland/labwc workaround)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh.
#
# Ubuntu Budgie 26.04 is Wayland-only (labwc compositor), and Budgie
# 10.10's panel ignores every "primary display" setting - it always
# lands on the first Wayland output the compositor advertises, which on
# a laptop is the built-in eDP screen. budgie-desktop-services records
# primary_output in ~/.config/budgie-desktop/display-config-shim.toml,
# but budgie-panel doesn't read it - a known gap in the Wayland
# transition (https://discourse.ubuntubudgie.org/t/7818). Toggling the
# eDP output off/on re-creates its Wayland output global, pushing it to
# the end of the output list; the external monitor becomes first and
# the panel jumps to it.
#
# Installs a login-time autostart entry that does that toggle. Inert
# everywhere the workaround doesn't apply: this function is a no-op
# unless budgie-desktop is installed, the autostart entry only runs in
# Budgie sessions (OnlyShowIn), and the script itself bails unless it
# finds a Wayland session, wlr-randr, and both a built-in and an
# external output. Remove once budgie-desktop honors primary_output.
#
# The Exec line runs the script through bash rather than relying on the
# exec bit so a lost bit (e.g. a restore that drops permissions) can't
# silently disable the workaround. Idempotent - safe to re-run.
######################################################################
configure_budgie_panel_primary_display() {
  pkg_installed budgie-desktop || return 0

  local script_file="$HOME/.local/bin/budgie-panel-to-external.sh"
  local autostart_file="$HOME/.config/autostart/budgie-panel-to-external.desktop"
  local script autostart

  script="$(
    cat <<'EOF'
#!/bin/bash
# Installed by dotfiles (scripts/dev_box/lib/budgie_panel.sh) - see there
# for the full story. Moves the Budgie panel to the external monitor by
# toggling the laptop screen's Wayland output so it stops being "first".
# Safe to run by hand after plugging in a monitor mid-session.

# Only meaningful in a Wayland session with wlroots output tooling.
[ -n "$WAYLAND_DISPLAY" ] || exit 0
command -v wlr-randr >/dev/null 2>&1 || exit 0

# Let the session and budgie-panel finish starting first.
sleep 8

# Output names sit at column zero; per-output details are indented.
outputs="$(wlr-randr | grep '^[^ ]' | cut -d' ' -f1)"

# Nothing to do without both a built-in output and an external one.
echo "$outputs" | grep -q '^eDP' || exit 0
echo "$outputs" | grep -qv '^eDP' || exit 0

edp="$(echo "$outputs" | grep '^eDP' | head -n1)"

# Capture the position first so re-enabling puts the screen back where
# the saved layout had it, instead of wherever the compositor guesses.
pos="$(wlr-randr | awk -v out="$edp" '$1 == out {found=1} found && $1 == "Position:" {print $2; exit}')"

wlr-randr --output "$edp" --off
sleep 2
wlr-randr --output "$edp" --on --pos "${pos:-0,0}"
EOF
  )"

  autostart="$(
    cat <<EOF
[Desktop Entry]
Type=Application
Name=Budgie panel to external monitor
Comment=Reorders Wayland outputs so the Budgie panel lands on the external monitor
Exec=bash $HOME/.local/bin/budgie-panel-to-external.sh
OnlyShowIn=Budgie;
X-GNOME-Autostart-enabled=true
EOF
  )"

  mkdir -p "$HOME/.local/bin" "$HOME/.config/autostart"

  if [[ ! -f "$script_file" ]] || [[ "$(cat "$script_file")" != "$script" ]]; then
    echo "$script" >"$script_file"
    chmod +x "$script_file"
  fi

  if [[ ! -f "$autostart_file" ]] || [[ "$(cat "$autostart_file")" != "$autostart" ]]; then
    echo "$autostart" >"$autostart_file"
  fi
}
