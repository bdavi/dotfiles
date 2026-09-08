---
name: write-ticket
description: Write, review, estimate, or create a Jira ticket (Tech Task or Inquiry) - the summary, description, story points, and creation mechanics. Use when drafting or editing a single ticket's content, or when creating/superseding tickets in Jira after sign-off. For planning a whole epic or structuring a list of tickets, use plan-epics, which defers here for each individual ticket.
---

# Writing a Jira ticket

How to write one ticket a developer can build from. Derived from the Comoto planning process (proven end-to-end on APP-1164 → APP-1166 and its twelve tickets).

## Is it a ticket at all?

Only write tickets **a developer will complete**. Two types cover it:

| Type | For |
|---|---|
| **Tech Task** | Build the thing. The answer is known; the work is to do it. |
| **Inquiry** | Answer a question or settle a design. Discovery, spikes, exploration. |

Work no developer performs - vendor calls, pricing, product/security sign-off, another team's DNS change - does **not** get a ticket. It goes on a non-developer follow-up list with an owner against each item. If it is later handed to a developer, it becomes a ticket then.

Sub-tasks and the Acceptance Criteria field are not used. No user-story phrasing ("As a ... I want ...") - write plainly.

## Summary

`<prefix> <Imperative description of the work>` - e.g. `2. Add podcast_episodes endpoints in ecom_api`

The prefix carries intended execution order within an epic, in one of three forms: plain numbers (`1.`) when execution is linear, letter-number (`A1.`) when there are parallel workstreams (see plan-epics), and **no prefix** when dependencies force no order. A standalone ticket needs no prefix. Vague summaries (`Update the importer`) are the failure mode; imperative and specific is the fix.

## Description

No fixed template. Lead with the deliverable and get concrete immediately. Include whichever apply: concrete deliverables (exact columns, module names, fields), a precedent to copy (a PR link or file path - having read it first), an `## Approach` section on bigger tickets (the chosen mechanism and rejected alternatives with reasons), explicit non-scope (`!! Images will be handled separately`), scope at layer boundaries (does this ticket ship the function, the endpoint, or both - and what owns the other half), dependencies by name, non-obvious follow-through, cleanup steps for one-off jobs, reference data (row counts, feed URLs), acceptance criteria (observably true when done - "re-running the import creates no duplicate comments", not "make it idempotent"), and the edge cases specific to *this* ticket - not the ones any competent developer already handles.

**Some tickets get no description at all.** "Run the import, work with biz to troubleshoot" needs nothing more than its summary.

The test: **could someone who wasn't in the planning conversation start this ticket without asking a question?** If the answer depends on a decision nobody has made yet, write an Inquiry instead.

## Self-contained is the standard

**The ticket must be buildable by someone holding the repo and nothing else** - a developer who missed the planning, or an agent with no conversation behind it. Five things are always present:

| Present | Not this |
|---|---|
| **A named deliverable** - module, function, arity: `RedlineCRM.Community.check_username/1` | "Answer whether this username is available" |
| **A real file path** - `redline/apps/redline_crm/lib/redline_crm/community.ex` | "Where this lives: `RedlineCRM.Community`" |
| **Cross-references that name the artifact** - "re-check with `Community.check_username/1` (ticket 4)" | "re-check with ticket 4" |
| **Precedent by path, and line where it helps** - `email.ex:303` | "modelled on the loyalty flow" |
| **A return contract**, where callers branch on it | "returns a result" |

🔴 A ticket that cannot name its own deliverable breaks every ticket downstream of it, which can then only point at a number. Naming propagates; vagueness propagates further.

⚠️ **No open questions inside a Tech Task.** "Decide before building" means the ticket is not ready: resolve it while planning, or make it an Inquiry.

## Inquiries

An Inquiry exists when the next useful thing a developer can produce is an *answer*, not code.

- Summary names the question or the thing being designed - `Design the native image uploader`. A `SPIKE ` prefix is optional.
- Description is a list of open questions, not a solution. Separate **"Decisions already made"** from **"What needs deciding"**.
- Name the people to coordinate with; an unnamed contact is a blocker in disguise.
- State the deliverable - usually a recommendation plus the Tech Tasks to implement it.

Two triggers for an Inquiry over a Tech Task: the work would otherwise be an 8, or 🔴 **the approach is unvalidated, whatever the size** - a small ticket with a confident-sounding mechanism nobody has pressure-tested reads as ready and gets half-built before the mechanism fails.

## Voice

Write what is to be built; the reader is the implementing developer.

- Lead with the deliverable, not the rationale - modules, endpoints, columns, file paths first.
- Keep *why* to a clause, and only where it prevents a wrong implementation.
- Cut anything that argues for the ticket - value statements, contrastive framing ("load-bearing, not an optimization"), celebratory emphasis. The ticket exists; it doesn't need selling.
- Say what we are building, not what we are not. The exception is a genuine trap - an unsafe default, a similar-looking pattern that must not be copied.
- Leave the decision history out; it belongs in the design doc.
- The delete test: would the developer act differently if this sentence were deleted? If not, cut it.
- Reserve 🔴 for traps that will cause defects and ⚠️ for worth-knowing; both survive into Jira as plain Unicode. If everything is emphasised, nothing is.
- **Do not hard-wrap markdown prose.** One long line per paragraph, list item, and table row; fenced code blocks keep real line breaks.

## Estimation

Fibonacci: 1 (quick hit, < ½ day) · 2 (simple, < 1 day) · 3 (medium, < 2 days) · 5 (advanced, < 1 week, the working ceiling) · 8 (too big - split it or front it with an Inquiry).

- Most tickets land at 1-3; a 5 that reflects real scope beats three fictional 2s.
- **Inquiries are pointed too - 3 is the default.** An Inquiry's estimate is usually a time-box: how long we are willing to spend on the question. An unpointed Inquiry is a mistake.
- Points go on Tech Tasks and Inquiries, never the epic (its total is the sum of its children).
- 🔴 **One PR, one deploy, one ticket.** There is no separate config-push mechanism at Comoto - a config-only change is still a full deploy, and deploy boundaries are ticket boundaries. Any ordered rollout (ship a capability, then switch it on; dual-write migrations; mixed-version windows) splits into one ticket per deploy. Never propose "config change, not a deploy" - that option does not exist here.

## Verify before you write

The most expensive mistakes in a plan are confident sentences nobody checked. Before writing the ticket:

1. **Has the code moved?** Check `git log` for the area - work merges while plans are drafted, and a ticket describing done work gets built twice.
2. **Is the number measured or assumed?** Run the query, parse the file, count it. Say where a number came from and when ("measured in production, 2026-08-25") - a bare number cannot be told apart from a guess.
3. **Does the precedent do what you claim?** Read the file before writing "follow the pattern in X" - it may contain a defect that must not be copied, which earns its own line in the ticket.
4. **Does the live system agree?** Where the answer is in production and reading it is safe, read it.

A measurement that decides a design is a prerequisite with an owner, not homework. Ask for aggregates, never row-level data.

## Creating it in Jira

🔴 **Nothing is created until there is a positive, explicit go-ahead.** Silence, "looks good", or a conversation that moved on is not sign-off. **"Write it up" means put it in the plan document** - it is never an instruction to create tickets.

Mechanics - required fields, project-specific ids, API quirks, superseding existing tickets - are in [jira-reference.md](jira-reference.md). Read it before any create or bulk operation.
