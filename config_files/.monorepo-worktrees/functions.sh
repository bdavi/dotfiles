# Worktree-scoped dev environments for the Comoto monorepo.
#
# Sourced from ~/.workrc. See ~/.monorepo-worktrees/README.md.
#
# Each worktree gets a slot letter, and the letter derives everything: the
# checkout at ~/worktrees/<letter>, the compose project wt<letter>, container
# names wt<letter>-<service>, the hostnames <letter>-{rz,cg,jp}.devzla.com, and
# the network 172.30.<index>.0/24 with the nginx sidecar pinned at .10.
#
# Written to work in both bash and zsh, so no arrays and no word-splitting of
# unquoted variables.

WT_PRIMARY_REPO="${WT_PRIMARY_REPO:-$HOME/monorepo}"
WT_ROOT="${WT_ROOT:-$HOME/worktrees}"
WT_STATE_ROOT="${WT_STATE_ROOT:-$HOME/.local/share/wt}"
WT_TOOLS_DIR="${WT_TOOLS_DIR:-$HOME/.monorepo-worktrees}"
WT_PYTHON="${WT_PYTHON:-/usr/bin/python3}"

#
# HELPERS
#

_wt_err() { printf '%s\n' "$*" >&2; }

# short brand name -> compose service name
_wt_service() {
  case "$1" in
    cg)   printf 'cycle-gear-redline-webapp' ;;
    rz)   printf 'revzilla-redline-webapp' ;;
    jp)   printf 'jp-cycles-redline-webapp' ;;
    ecom) printf 'ecom-webapp' ;;
    *)    return 1 ;;
  esac
}

_wt_index() {
  _i=0
  for _l in a b c d e f g h i j k l m n o p q r s t; do
    _i=$((_i + 1))
    if [ "$_l" = "$1" ]; then printf '%s' "$_i"; unset _i _l; return 0; fi
  done
  unset _i _l
  return 1
}

# The slot letter for the current directory, or failure. Identity comes from the
# worktree path, never the branch, because a worktree is an ordinary checkout
# and you can switch branches inside it.
_wt_letter() {
  _top=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  [ -f "$_top/.git" ] || return 1   # in a linked worktree .git is a file, not a dir
  _letter="${_top##*/}"
  [ -d "$WT_STATE_ROOT/$_letter" ] || return 1
  printf '%s' "$_letter"
  unset _top _letter
}

# Sets _WT_L / _WT_DIR / _WT_STATE for the current worktree.
_wt_require() {
  _WT_L=$(_wt_letter) || { _wt_err "not in a monorepo worktree"; return 1; }
  _WT_DIR="$WT_ROOT/$_WT_L"
  _WT_STATE="$WT_STATE_ROOT/$_WT_L"
  return 0
}

_wt_container() { printf 'wt%s-%s' "$1" "$2"; }

_wt_running() { docker ps --format '{{.Names}}' | grep -qx "$1"; }

# Echoes the container name, or explains how to start it.
_wt_need() {
  _c=$(_wt_container "$1" "$2")
  if ! _wt_running "$_c"; then
    _wt_err "$_c is not running."
    _wt_err "start it with:  wdc up -d --scale $_c=1"
    unset _c
    return 1
  fi
  printf '%s' "$_c"
  unset _c
}

# Runs a command in a brand's container. The banner matters: a missing `w`
# silently targets the primary stack instead.
_wt_exec() {
  _wt_require || return 1
  _svc=$(_wt_service "$1") || { _wt_err "unknown brand: $1"; return 1; }
  _c=$(_wt_need "$_WT_L" "$_svc") || { unset _svc; return 1; }
  printf '→ %s\n' "$_c"
  _wt_exec_raw "$_c" "$2"
}

# Same, without the banner (used where the target is shared anyway).
_wt_exec_quiet() {
  _wt_require || return 1
  _svc=$(_wt_service "$1") || { _wt_err "unknown brand: $1"; return 1; }
  _c=$(_wt_need "$_WT_L" "$_svc") || { unset _svc; return 1; }
  _wt_exec_raw "$_c" "$2"
}

_wt_exec_raw() {
  if [ -z "$2" ]; then
    docker exec -it -u deploy "$1" bash -lc "TERM=xterm-color bash -l"
  else
    docker exec -it -u deploy "$1" bash -lc "$2"
  fi
}

# The dev iex cookie is read from the monorepo at runtime rather than
# embedded here: this repo is public, the monorepo is not, and the
# cookie's value belongs there. It's parsed out of the same iex helpers
# the primary stack's commands use (zlaverse/support/bash_functions.sh),
# so it can't drift, and these commands only work with the monorepo
# checked out anyway.
_wt_cookie() {
  _ck=$(sed -n 's/.*--cookie \([A-Za-z0-9_]*\).*/\1/p' \
    "$WT_PRIMARY_REPO/zlaverse/support/bash_functions.sh" 2>/dev/null | head -n 1)
  if [ -z "$_ck" ]; then
    _wt_err "couldn't read the dev iex cookie from $WT_PRIMARY_REPO/zlaverse/support/bash_functions.sh"
    unset _ck
    return 1
  fi
  printf '%s' "$_ck"
  unset _ck
}

# Remote iex into a brand's running app. The backticks are escaped so
# `hostname` runs in the container, not here.
_wt_iex() {
  _ck=$(_wt_cookie) || return 1
  _wt_exec "$1" "TERM=xterm-color iex --sname console --remsh $1@\`hostname\` --cookie $_ck"
  unset _ck
}

_wt_logs() {
  _wt_require || return 1
  _svc=$(_wt_service "$1") || { _wt_err "unknown brand: $1"; return 1; }
  _c=$(_wt_need "$_WT_L" "$_svc") || { unset _svc; return 1; }
  printf '→ %s\n' "$_c"
  docker logs -f --tail 1000 "$_c"
}

_wt_open() {
  _wt_require || return 1
  case "$1" in
    ecom) _url="https://$_WT_L-rz.devzla.com/admin" ;;   # ecom has no host of its own
    *)    _url="https://$_WT_L-$1.devzla.com" ;;
  esac
  printf '→ %s\n' "$_url"
  xdg-open "$_url" >/dev/null 2>&1 &
  unset _url
}

# OpenSSH refuses any file under ~/.ssh that is group- or world-writable, and the
# container mounts the host's ~/.ssh to fetch the git dependencies. One loose mode
# bit and the cold `mix deps.get` dies partway through with `Bad owner or
# permissions on /home/deploy/<file>`, leaving a half-populated deps volume.
#
# 600 rather than a plain `go-w`, because the writable file could be either a
# config (rejected only when writable) or a private key (also rejected when
# merely group-readable), and 600 satisfies both. `.pub` files are meant to stay
# readable, so those only lose the write bits.
#
# Runs on the host, so the primary stack's cold rebuilds benefit too.
_wt_ssh_preflight() {
  [ -d "$HOME/.ssh" ] || return 0

  _bad=$(find "$HOME/.ssh" -maxdepth 1 -type f -perm /go+w 2>/dev/null)
  [ -n "$_bad" ] || { unset _bad; return 0; }

  printf '%s\n' "$_bad" | while IFS= read -r _f; do
    [ -n "$_f" ] || continue
    case "$_f" in
      *.pub) _mode=go-w ;;
      *)     _mode=600 ;;
    esac
    if chmod "$_mode" "$_f" 2>/dev/null; then
      printf 'ssh: chmod %s %s — ssh refuses group/world-writable files\n' "$_mode" "$_f"
    else
      _wt_err "ssh: could not chmod $_mode $_f — a cold deps.get will fail on it"
    fi
  done

  unset _bad _f _mode
}

# nginx resolves upstream names once at startup, so confs are refreshed and the
# sidecar restarted whenever app containers are created or recreated.
_wt_refresh_gateway() {
  _idx=$(_wt_index "$_WT_L") || return 1
  "$WT_PYTHON" "$WT_TOOLS_DIR/wt-generate.py" \
    --letter "$_WT_L" --index "$_idx" --worktree "$_WT_DIR" --state "$_WT_STATE" \
    --nginx-only >/dev/null || return 1
  _gw=$(_wt_container "$_WT_L" gateway)
  if docker ps -a --format '{{.Names}}' | grep -qx "$_gw"; then
    docker restart "$_gw" >/dev/null 2>&1
  fi
  unset _idx _gw
}

#
# COMMANDS
#

# wnew <branch> — create a worktree for a new, existing, or remote branch.
wnew() {
  if [ -z "$1" ]; then
    _wt_err "usage: wnew <branch>     e.g. wnew bdavi/APP-1234"
    _wt_err "                              wnew origin/hwideman/APP-1069"
    return 1
  fi

  # Any checkout of the monorepo will do - the primary or one of its
  # worktrees. Worktrees share refs, remotes, and the worktree list with
  # the primary, so every git command below behaves identically from
  # either; the check only rejects shells that aren't in the monorepo at
  # all. --git-common-dir resolves to the primary's .git from any of
  # them (the same fact the wt-generate.py .git mount leans on).
  _common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  if [ "$_common" != "$WT_PRIMARY_REPO/.git" ]; then
    _wt_err "wnew runs from the primary monorepo or one of its worktrees ($WT_PRIMARY_REPO)"
    unset _common
    return 1
  fi
  unset _common

  _name="$1"
  _explicit_remote=0
  case "$1" in
    origin/*) _name="${1#origin/}"; _explicit_remote=1 ;;
  esac

  if git worktree list --porcelain | grep -qx "branch refs/heads/$_name"; then
    _wt_err "branch $_name is already checked out in another worktree"
    return 1
  fi

  # Resolve what kind of branch this is, and say so.
  if [ "$_explicit_remote" -eq 1 ]; then
    git fetch origin "$_name" || { _wt_err "could not fetch origin/$_name"; return 1; }
    if git show-ref --verify --quiet "refs/heads/$_name"; then
      _mode=existing
    else
      _mode=track
    fi
  elif git show-ref --verify --quiet "refs/heads/$_name"; then
    _mode=existing
  elif git ls-remote --exit-code --heads origin "$_name" >/dev/null 2>&1; then
    git fetch origin "$_name" || return 1
    _mode=track
  else
    _mode=new
    case "$_name" in
      */[A-Z][A-Z]*-[0-9]*) : ;;
      *) _wt_err "new branches should look like <handle>/<TICKET-123> — got '$_name'"; return 1 ;;
    esac
  fi

  case "$_mode" in
    existing) printf 'using existing local branch %s\n' "$_name" ;;
    track)    printf 'branch exists on origin — creating local %s tracking origin/%s\n' "$_name" "$_name" ;;
    new)      printf 'creating new branch %s off local master\n' "$_name" ;;
  esac

  _letter=""
  for _l in a b c d e f g h i j k l m n o p q r s t; do
    if [ ! -d "$WT_STATE_ROOT/$_l" ] && [ ! -e "$WT_ROOT/$_l" ]; then
      _letter="$_l"
      break
    fi
  done
  if [ -z "$_letter" ]; then _wt_err "no free slots (a-t are all in use)"; return 1; fi
  _idx=$(_wt_index "$_letter")
  _dir="$WT_ROOT/$_letter"
  _state="$WT_STATE_ROOT/$_letter"

  mkdir -p "$WT_ROOT" "$_state" || return 1

  case "$_mode" in
    existing) git worktree add "$_dir" "$_name" ;;
    track)    git worktree add --track -b "$_name" "$_dir" "origin/$_name" ;;
    new)      git worktree add -b "$_name" "$_dir" master ;;
  esac
  if [ $? -ne 0 ]; then
    rmdir "$_state" 2>/dev/null
    _wt_err "git worktree add failed"
    return 1
  fi

  if [ ! -f "$_state/compose.override.yaml" ]; then
    {
      printf '# Hand-edited overrides for slot %s (%s). Survives wregen.\n' "$_letter" "$_name"
      printf '#\n# Enable another brand by replacing the {} below:\n#\n'
      printf '# services:\n#   wt%s-revzilla-redline-webapp:\n#     scale: 1\n' "$_letter"
      printf 'services: {}\n'
    } > "$_state/compose.override.yaml"
  fi

  "$WT_PYTHON" "$WT_TOOLS_DIR/wt-generate.py" \
    --letter "$_letter" --index "$_idx" --worktree "$_dir" --state "$_state" || return 1

  _ws=""
  if [ -n "$HERDR_ENV" ]; then
    _ws=$(herdr workspace create --cwd "$_dir" --label "$_name" --focus 2>/dev/null |
      "$WT_PYTHON" -c 'import json, sys
try:
    result = json.load(sys.stdin).get("result", {})
except Exception:
    print("")
else:
    print(result.get("workspace", {}).get("workspace_id")
          or result.get("workspace_id", ""))' 2>/dev/null)
  fi

  {
    printf 'WT_LETTER=%s\n' "$_letter"
    printf 'WT_INDEX=%s\n' "$_idx"
    printf 'WT_BRANCH=%s\n' "$_name"
    printf 'WT_PATH=%s\n' "$_dir"
    printf 'WT_MODE=%s\n' "$_mode"
    printf 'WT_HERDR_WORKSPACE=%s\n' "$_ws"
  } > "$_state/meta"

  printf '\nslot %s   %s\n' "$_letter" "$_dir"
  printf '  https://%s-rz.devzla.com   https://%s-cg.devzla.com   https://%s-jp.devzla.com\n' \
    "$_letter" "$_letter" "$_letter"
  printf '  next:  wdc up -d      (cycle gear only; other services are scale 0)\n\n'

  # Land in the new worktree only when no herdr workspace was opened for
  # it. Inside herdr that workspace already gets its own panes at the
  # worktree root, and cd'ing here would drag the invoking pane - the
  # primary monorepo one - into the worktree too.
  if [ -z "$_ws" ]; then
    cd "$_dir" || return 1
  fi
  unset _name _explicit_remote _mode _letter _l _idx _dir _state _ws
}

# wdel [--force] — tear down and remove the current worktree. Keeps the branch.
wdel() {
  _wt_require || return 1

  _force=0
  [ "$1" = "--force" ] && _force=1

  _branch=$(git -C "$_WT_DIR" branch --show-current 2>/dev/null)
  _dirty=$(git -C "$_WT_DIR" status --porcelain --untracked-files=no 2>/dev/null)
  if git -C "$_WT_DIR" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    _ahead=$(git -C "$_WT_DIR" log --oneline '@{u}..HEAD' 2>/dev/null)
  else
    _ahead=$(git -C "$_WT_DIR" log --oneline origin/master..HEAD 2>/dev/null)
  fi

  if [ "$_force" -eq 0 ]; then
    if [ -n "$_dirty" ]; then
      _wt_err "uncommitted changes in $_WT_DIR — commit them, or wdel --force"
      return 1
    fi
    if [ -n "$_ahead" ]; then
      _wt_err "unpushed commits on $_branch — push them, or wdel --force"
      printf '%s\n' "$_ahead" >&2
      return 1
    fi
  fi

  if [ -n "$(git -C "$_WT_DIR" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    printf 'note: untracked files in the worktree will be removed\n'
  fi

  _letter="$_WT_L"
  _dir="$_WT_DIR"
  _state="$_WT_STATE"
  _ws=$(sed -n 's/^WT_HERDR_WORKSPACE=//p' "$_state/meta" 2>/dev/null)

  cd "$WT_PRIMARY_REPO" || return 1   # the cwd is about to stop existing

  docker compose -p "wt$_letter" \
    -f "$_state/compose.yaml" -f "$_state/compose.override.yaml" \
    down -v --remove-orphans 2>/dev/null

  if [ "$_force" -eq 1 ]; then
    git worktree remove --force "$_dir" || return 1
  else
    git worktree remove "$_dir" || return 1
  fi

  rm -rf "$_state"
  printf 'slot %s removed. branch %s kept.\n' "$_letter" "$_branch"

  if [ -n "$_ws" ]; then
    if [ "$_ws" = "$HERDR_WORKSPACE_ID" ]; then
      printf 'this herdr workspace (%s) belonged to that worktree — close it when you are done here.\n' "$_ws"
    else
      herdr workspace close "$_ws" >/dev/null 2>&1
    fi
  fi

  unset _force _branch _dirty _ahead _letter _dir _state _ws
}

# wls — every slot: letter, branch (read live), containers up, URL.
wls() {
  if [ ! -d "$WT_STATE_ROOT" ]; then printf 'no worktrees\n'; return 0; fi
  printf '%-5s %-36s %-5s %s\n' SLOT BRANCH UP URL
  for _d in "$WT_STATE_ROOT"/*; do
    [ -d "$_d" ] || continue
    _letter="${_d##*/}"
    _branch=$(git -C "$WT_ROOT/$_letter" branch --show-current 2>/dev/null)
    [ -n "$_branch" ] || _branch='(detached or missing)'
    _up=$(docker ps --format '{{.Names}}' | grep -c "^wt$_letter-")
    printf '%-5s %-36s %-5s %s\n' "$_letter" "$_branch" "$_up" "https://$_letter-cg.devzla.com"
  done
  unset _d _letter _branch _up
}

# windex — the current slot letter, bare, for scripting.
windex() {
  _wt_require || return 1
  printf '%s\n' "$_WT_L"
}

# wdc … — docker compose scoped to this worktree.
wdc() {
  _wt_require || return 1
  if ! docker network inspect zla_default >/dev/null 2>&1; then
    _wt_err "the primary stack's network (zla_default) does not exist — start the primary monorepo stack first"
    return 1
  fi
  _sub="$1"
  case "$_sub" in
    up|start|restart) _wt_ssh_preflight ;;
  esac
  docker compose -p "wt$_WT_L" \
    -f "$_WT_STATE/compose.yaml" -f "$_WT_STATE/compose.override.yaml" "$@"
  _rc=$?
  case "$_sub" in
    up|start|restart)
      if [ "$_rc" -eq 0 ]; then _wt_refresh_gateway; fi
      ;;
  esac
  unset _sub
  return $_rc
}

# wregen — rewrite the generated compose file and nginx confs from the branch.
wregen() {
  _wt_require || return 1
  _idx=$(_wt_index "$_WT_L") || return 1
  "$WT_PYTHON" "$WT_TOOLS_DIR/wt-generate.py" \
    --letter "$_WT_L" --index "$_idx" --worktree "$_WT_DIR" --state "$_WT_STATE"
  unset _idx
}

#
# BRAND WRAPPERS
#

wcg-log()  { _wt_logs cg; }
wrz-log()  { _wt_logs rz; }
wjp-log()  { _wt_logs jp; }
wecom-log() { _wt_logs ecom; }

wcg-bash()  { _wt_exec cg "$1"; }
wrz-bash()  { _wt_exec rz "$1"; }
wjp-bash()  { _wt_exec jp "$1"; }
wecom-bash() { _wt_exec ecom "$1"; }

wcg-iex() { _wt_iex cg; }
wrz-iex() { _wt_iex rz; }
wjp-iex() { _wt_iex jp; }

wcg-open()   { _wt_open cg; }
wrz-open()   { _wt_open rz; }
wjp-open()   { _wt_open jp; }
wecom-open() { _wt_open ecom; }

# Test-schema rebuilds. No banner: the databases are shared with the primary
# stack either way, so the only difference is whose schema dump gets loaded.
welts() { _wt_exec_quiet ecom 'RAILS_ENV=test; rake db:test:reset_and_load_seed'; }
wclts() { _wt_exec_quiet cg '(export MIX_ENV=test && mix compile && cd apps/redline_core_model && mix ecto.reset_test_repo)'; }
