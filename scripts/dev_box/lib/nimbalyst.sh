#!/usr/bin/env bash

######################################################################
# Nimbalyst (github.com/nimbalyst/nimbalyst)
######################################################################
# Not meant to be run directly - sourced by build_ubuntu.sh, after
# util.sh and github.sh (needs github_latest_release).
#
# Desktop app for running multiple parallel Claude Code/Codex sessions,
# each in its own git worktree, with a kanban view across them - the
# official successor to stravu/crystal (deprecated Feb 2026). Only
# distributed as a single Linux AppImage on GitHub Releases - no apt
# repo, snap, or flatpak - so this follows the same fixed-directory,
# re-extract-on-update pattern lib/neovim.sh uses for tools apt can't
# keep current, rather than lib/vscode.sh's apt-repo approach.
######################################################################

install_nimbalyst() {
  local latest
  latest="$(github_latest_release nimbalyst/nimbalyst 0)"

  if [[ -z "$latest" ]]; then
    echo "Could not resolve latest nimbalyst v0 release" >&2
    exit 1
  fi

  local install_dir="$HOME/.local/share/nimbalyst"
  local version_file="$install_dir/.version"

  # Stamped explicitly rather than read back from the app: the AppImage's
  # own embedded X-AppImage-Version is electron-builder's internal build
  # metadata, not the GitHub release tag, so it can't be compared against
  # github_latest_release's output.
  if [[ -x ~/.local/bin/nimbalyst && "$(cat "$version_file" 2>/dev/null)" == "$latest" ]]; then
    echo "nimbalyst $latest already installed"
    return 0
  fi

  rm -rf "$install_dir"
  mkdir -p "$install_dir"

  local appimage="$install_dir/Nimbalyst.AppImage"
  curl -fsSL \
    "https://github.com/nimbalyst/nimbalyst/releases/download/${latest}/Nimbalyst-Linux.AppImage" \
    -o "$appimage"
  chmod +x "$appimage"

  # Extracted rather than run in place: the AppImage self-mounts its
  # squashfs to a fresh random path under /tmp on every launch, which is
  # both slower to start and leaves nothing stable for the symlink/icon
  # below to point at.
  (cd "$install_dir" && "$appimage" --appimage-extract >/dev/null)
  local extract_dir="$install_dir/squashfs-root"
  local bin="$extract_dir/@nimbalystelectron"

  # Ubuntu 24.04+ restricts unprivileged user namespaces by default
  # (kernel.apparmor_restrict_unprivileged_userns=1), which breaks
  # Chromium's normal sandbox. The proper fix is chown-root + setuid on
  # the bundled chrome-sandbox helper, but that needs an interactive
  # sudo prompt this script can't give it non-interactively - so this
  # runs unsandboxed instead, same as the AppImage's own shipped
  # .desktop entry (@nimbalystelectron.desktop) defaults to.
  mkdir -p ~/.local/bin
  cat >~/.local/bin/nimbalyst <<EOF
#!/usr/bin/env bash
exec "$bin" --no-sandbox "\$@"
EOF
  chmod +x ~/.local/bin/nimbalyst
  echo "$latest" >"$version_file"

  # .desktop entry and icon: adapted from the ones the AppImage ships
  # internally (@nimbalystelectron.desktop/.png) - points Exec at the
  # wrapper above instead of AppRun, which re-extracts to a fresh /tmp
  # path every launch.
  mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/1024x1024/apps
  cp -f "$extract_dir/usr/share/icons/hicolor/1024x1024/apps/@nimbalystelectron.png" \
    ~/.local/share/icons/hicolor/1024x1024/apps/nimbalyst.png
  cat >~/.local/share/applications/nimbalyst.desktop <<EOF
[Desktop Entry]
Name=Nimbalyst
Comment=Visual workspace for parallel Claude Code / Codex sessions
Exec=$HOME/.local/bin/nimbalyst %U
Terminal=false
Type=Application
Icon=nimbalyst
StartupWMClass=Nimbalyst
Categories=Development;
EOF

  echo "Installed nimbalyst $latest to $extract_dir (symlinked at ~/.local/bin/nimbalyst)"
}
