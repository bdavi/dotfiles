---
name: write-pr-description
description: Write or edit a GitHub pull request description, including QA/test-plan steps. Use when opening a PR, filling in a PR body or template, updating an existing PR's description, or writing QA steps for a change.
---

# Writing a PR description

The organizing principle: **the reviewer's time is more valuable than yours.** Every sentence in the description and every QA step exists to spend your effort so the reviewer doesn't spend theirs - anything that makes them reconstruct context, re-derive setup, or discover a known weakness on their own is a failure of the description, not of the review.

## Ground rules

- PRs are always **drafts** on first push, and pushes only happen when explicitly requested.
- **Always use the repo's default PR description template** - fill its sections in rather than replacing it with a custom summary/test-plan body.

## Content: the current state, nothing else

A reviewer reads the description to review the diff in front of them. Describe **what the PR does now**.

Cut: commit-by-commit narrative (the GitHub UI lists commits), how the branch got here, steps since superseded (a temporary pin later moved to a real tag, a design reworked mid-branch), and open questions parked with product or another team that do not block review.

Keep - the things a reviewer cannot get from the diff:

- Design decisions they would otherwise challenge.
- Contract details clients depend on: error codes, response shapes.
- **Acknowledged shortcomings of the approach** - the known weaknesses, stated before the reviewer finds them. Pre-empting the round-trip is cheaper than having it.
- **Deploy notes**: migrations, env vars, feature flags, breaking changes and their migration path. One PR is one deploy, so the description is where the deploy's requirements live.
- **The full QA steps.** QA is followed literally, so trimming there costs more than it saves.

Voice matches ticket writing: plain declaratives, lead with what changed, no selling, no contrastive framing. **No hard-wrapped markdown** - one long line per paragraph or list item.

## QA / test-plan steps

Three main ways to exercise a change - pick whichever fits:

1. Through the UI.
2. Via a REPL (`iex`, `irb`, or the language's equivalent).
3. Via API endpoints (SwaggerUI or similar).

Keep the instructions simple, and include **all** setup needed to actually follow them - seed data, env vars, how to start the REPL or server. Assume no prior context: the QA reader was not in the planning conversation and will type exactly what is written. Their time is the expensive side of the exchange - a minute spent writing the exact seed command saves every QA pass that would otherwise reconstruct it.

## Editing an existing PR description

🔴 **Fetch the live body first and edit that** - `gh pr view <n> --json body -q .body`. `gh pr edit --body-file` is a full replacement with no conflict warning, and descriptions get edited directly on GitHub; a body composed locally silently destroys those edits. If the live body differs from what was last pushed, treat the live version as the base and merge changes into it.

The same discipline applies to any remote-editable body: Jira descriptions, Confluence pages.

**Before a PR leaves draft, re-read the description against the final diff.** Branches change during review - a description written at open time drifts into describing a PR that no longer exists.
