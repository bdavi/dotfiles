#!/bin/sh
# Claude Code statusline. Claude Code pipes a JSON payload (model, context
# window, rate limits) to this on stdin after each turn, and prints the
# first line of stdout under the prompt. Registered in ~/.claude/settings.json
# by install_claude_statusline in scripts/install_dotfiles.sh.
#
# It exists mainly to feed the herdr-claude-usage plugin
# (oszypczy/herdr-claude-usage, installed by lib/herdr.sh), which draws
# context / 5h / 7d usage bars in herdr's sidebar from this same payload -
# there's no other way to get at it. The plugin's own setup would insert the
# line below automatically, but it rewrites the script in place, and this one
# is tracked, so the line is written here by hand instead. It must stay right
# after input=$(cat), and keep its trailing marker comment, which is how the
# plugin's `remove` action finds it. Outside herdr, or with the plugin gone,
# it does nothing.
input=$(cat)
[ -n "$HERDR_PANE_ID" ] && [ -f "$HOME/.config/herdr/plugins/config/oszypczy.claude-usage/report.sh" ] && (printf "%s" "$input" | sh "$HOME/.config/herdr/plugins/config/oszypczy.claude-usage/report.sh" &) >/dev/null 2>&1 # claude-usage

printf '%s' "$input" | jq -r '"\(.model.display_name // "claude") · ctx \((.context_window.used_percentage // 0) | round)%"' 2>/dev/null
