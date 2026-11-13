#!/usr/bin/env bash
#
# PreToolUse guard for Bash commands that publish, rewrite history or destroy
# shared data.
#
# Two kinds of answer:
#
# - A hard exit-2 block for what agents never do, because none of it is a
#   decision to put behind a y/n keystroke: merging a pull request (gh pr merge,
#   or the merge endpoint through gh api) and force-pushing.
# - permissionDecision "ask" for what needs a person's approval every time:
#   git commit / git push, the outward-facing gh commands, gh api calls that
#   write, Ecto database resets and drops, and docker compose down with its
#   volumes.
#
# The hook, not the permission rules, is the mechanism. Hook output forces a
# prompt regardless of permission rules, so it holds where a broad allow rule
# such as "Bash(git *)" would otherwise let the command run silently, and in
# auto mode, where ask rules were verified not to fire (2026-09-14). Rules also
# only match from the start of a command, so they miss a command wrapped in
# another one ("docker exec app mix ecto.reset"); the database and compose
# checks below match anywhere in the command line for that reason.
#
# Exists because instruction text did not work: in one session the publishing
# rule was violated three times, twice within minutes of being written down.

set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0

# BOUNDARY anchors a pattern at the start of a command, so "git log
# --grep=commit" is not caught but a chained "git add -A && git commit" is.
BOUNDARY='(^|[;&|]|&&|\|\|)[[:space:]]*'
# "git", optionally behind sudo, followed by global options such as -C <path>.
GIT="${BOUNDARY}(sudo[[:space:]]+)?git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+"
# One argument that stays inside the current command.
ARG='[^;&|[:space:]]+'

GIT_WRITE="${GIT}(commit|push)([[:space:]]|\$)"
# --force, --force-with-lease, a short-flag cluster containing f (-f, -uf),
# or a +refspec, which forces that one ref.
FORCE_PUSH="${GIT}push([[:space:]]+${ARG})*[[:space:]]+(--force(-with-lease)?(=[^[:space:]]*)?|-[a-zA-Z]*f[a-zA-Z]*|\+[^[:space:]]+)([[:space:]]|\$)"
GH_WRITE="${BOUNDARY}gh[[:space:]]+(pr[[:space:]]+(create|edit)|repo[[:space:]]+(create|delete))([[:space:]]|\$)"
GH_MERGE="${BOUNDARY}gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|\$)"
# ecto.reset also covers aliases that start with it, such as ecto.reset_test_repo.
ECTO_DESTROY='ecto\.(reset|drop)'
COMPOSE_DOWN_VOLUMES="(docker[[:space:]]+compose|docker-compose)([[:space:]]+${ARG})*[[:space:]]+down([[:space:]]+${ARG})*[[:space:]]+(-v|--volumes)([[:space:]]|\$)"

matches() { printf '%s' "$cmd" | grep -qE "$1"; }

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

if matches "$GH_MERGE"; then
  block "agents never merge pull requests. The merge is yours to perform."
fi
if matches "$FORCE_PUSH"; then
  block "agents never force-push. Rewriting published history is yours to decide and perform."
fi

reasons=()

# gh api reads by default and writes when given a non-GET method, or fields or
# an --input body without one (gh then sends a POST). A GraphQL call writes only
# when it is a mutation; a query read from a file (=@path) can't be inspected
# here, so it is treated as a write.
while IFS= read -r call; do
  [ -n "$call" ] || continue
  writes=false
  if printf '%s' "$call" | grep -qE 'gh[[:space:]]+api[[:space:]]+graphql([[:space:]]|$)'; then
    if printf '%s' "$call" | grep -qiE 'mutation|=@'; then writes=true; fi
  else
    method="$(printf '%s' "$call" | grep -oiE '(^|[[:space:]])(-X|--method)[[:space:]=]*[A-Za-z]+' | tail -n1 | grep -oE '[A-Za-z]+$' | tr '[:lower:]' '[:upper:]')"
    if [ -z "$method" ] && printf '%s' "$call" | grep -qE '[[:space:]](-f|-F|--field|--raw-field|--input)([[:space:]=]|$)'; then
      method=POST
    fi
    case "${method:-GET}" in GET|HEAD) ;; *) writes=true ;; esac
  fi
  if $writes; then
    if printf '%s' "$call" | grep -qiE 'pulls/[0-9]+/merge|mergePullRequest'; then
      block "agents never merge pull requests, including through gh api. The merge is yours to perform."
    fi
    reasons+=("gh api call that writes to GitHub - needs approval every time.")
  fi
done < <(printf '%s' "$cmd" | grep -oE "${BOUNDARY}gh[[:space:]]+api([[:space:]]+[^;&|]*)?")

if matches "$GIT_WRITE" || matches "$GH_WRITE"; then
  reasons+=("Publishing command - needs approval every time. Authorization is single-use: a previous \"commit and push\" does not cover this one, and \"continue\" continues the task, not the publishing.")
fi
if matches "$ECTO_DESTROY"; then
  reasons+=("Drops or resets a database. Dev and test databases on this machine can be shared with other checkouts and worktrees, so a failed reload leaves all of them empty - needs approval every time.")
fi
if matches "$COMPOSE_DOWN_VOLUMES"; then
  reasons+=("docker compose down with -v deletes the stack's volumes, including any database data - needs approval every time.")
fi

if [ "${#reasons[@]}" -gt 0 ]; then
  reason="$(printf '%s ' "${reasons[@]}")"
  jq -nc --arg r "${reason% }" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
fi

exit 0
