#!/usr/bin/env bash
#
# PreToolUse guard for publishing commands.
#
# Forces a permission prompt for git commit / git push and the outward-facing
# gh commands, by returning permissionDecision "ask". Hook output can force a
# prompt regardless of permission rules, so this holds even where a broad
# "Bash(git *)" allow rule would otherwise let the command run silently.
#
# gh pr merge is the exception: a hard exit-2 block, because agents never
# merge and that is not a decision to put behind a y/n keystroke.
#
# Exists because instruction text did not work: in one session the same rule
# was violated three times, twice within minutes of being written down.

set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0

# Anchored at a command boundary so "git log --grep=commit" is not caught, and
# so a chained "git add -A && git commit" still is.
GIT_WRITE='(^|[;&|]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+(commit|push)([[:space:]]|$)'
GH_WRITE='(^|[;&|]|&&|\|\|)[[:space:]]*gh[[:space:]]+(pr[[:space:]]+(create|edit)|repo[[:space:]]+(create|delete))([[:space:]]|$)'
GH_MERGE='(^|[;&|]|&&|\|\|)[[:space:]]*gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'

if printf '%s' "$cmd" | grep -qE "$GH_MERGE"; then
  echo "BLOCKED: agents never merge pull requests. The merge is yours to perform." >&2
  exit 2
fi

if printf '%s' "$cmd" | grep -qE "$GIT_WRITE|$GH_WRITE"; then
  jq -nc --arg r "Publishing command - needs approval every time. Authorization is single-use: a previous \"commit and push\" does not cover this one, and \"continue\" continues the task, not the publishing." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
fi

exit 0
