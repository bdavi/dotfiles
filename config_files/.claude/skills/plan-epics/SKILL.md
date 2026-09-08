---
name: plan-epics
description: Plan an epic or a multi-epic programme - turn a requirement into a reviewed ticket list with build order, numbering, planning documents, and epic structure in Jira. Use when planning a feature that spans several tickets, writing an epic description, sequencing or splitting work across epics, or producing planning docs (summary/tickets/design). Each individual ticket's content follows the write-ticket skill.
---

# Planning an epic (or several)

How a requirement becomes an epic with tickets a team can execute. Every individual ticket obeys the **write-ticket** skill, including its verify-before-you-write checks and the sign-off gate; this skill covers everything that only exists when there is a *list*.

Match the machinery to the scenario: a single ticket needs none of this; one epic needs Parts 1-2 below; only work spanning epics needs Part 3. Review requirements skeptically before planning - look for missed items, edge cases and inconsistencies, and ask about anything unclear before writing tickets.

## Work high level first

Produce the whole list at low detail before writing any ticket in full - a plan delivered at full detail in one pass is unreviewable; the volume buries the decisions.

1. **Pass 1 - the list.** Every ticket as one line: title, points, dependencies. This is where scope, ordering, gaps and duplication get argued, and it is cheap to change.
2. **Pass 2 - detail, one ticket at a time**, driven by the reviewer.

Signs of going too deep too early: the reviewer is overwhelmed; whole tickets get rewritten after a scope decision one line would have surfaced; the list keeps being renumbered.

## Numbering and parallel paths

The summary prefix carries execution order, so the ticket list reads as the plan. Three forms:

- **Single chain:** flat numbers - `1.`, `2.`, `3.`
- **Nothing forces an order:** no prefix at all. A small epic of independent tickets reads better as a plain list than a fictional sequence.
- **Several paths:** a letter per workstream, a number within it (`A1`, `A2`, `B1`, `C1`).

Letter-scheme rules:

- A letter is a workstream - related tickets one person could carry. Two tickets in a letter may be parallel; the build order says so.
- A convergence point starts a new letter: a ticket needing input from two paths belongs to neither.
- Detached work gets its own letter, which makes "this blocks nothing" visible.
- 🔴 **Dependencies point at earlier letters or lower numbers - a hard rule, not a smell.** The scheme exists to make the dependency shape visible; a dependency pointing forward means the grouping is wrong. Restructure (usually a new letter at the convergence), never allow the exception.

**Renumber freely while the plan is a draft** - insertion tricks (`2b.`) exist to protect issue keys, and before creation there are none. ⚠️ Dependency lines survive a renumber; prose does not. Prefer naming the artifact over the number ("the settings module", not "ticket 3"), and after any renumber grep every number reference across **all** documents.

## Build order

A ticket list is not a plan until you can say how a team works through it. Every epic gets a build order answering: what can start on day one and how many people at once; where the paths converge (the ticket that unblocks the most downstream work is the milestone worth tracking); what is detached; what is blocked outside engineering (start those earliest - we do not control their latency); and the first checkpoint that proves something against reality rather than stubs, plus the earliest point a stakeholder can see output (rarely the same ticket).

**Sequence for feedback, not just for dependencies** - where two orderings both work, prefer the one that surfaces a wrong assumption sooner.

Every ticket carries `Depends on` and `Blocks` lines; state once at the top of the tickets file that bare numbers mean this epic. In Jira, express them as issue links (`Blocks` / `is blocked by`) once keys exist.

## The planning documents

An epic gets three files - different readers, different lifespans. Collapsing them turns the ticket write-up into a working notepad. They live in the repo's `discovery/` directory (create it if absent; confirm the location if the repo has another convention), numbered in execution order - `01` is what gets built first, and a later insertion renumbers rather than appends.

| File | Reader | Contains |
|---|---|---|
| `NN-<epic>-summary.md` | Anyone wanting the shape | Overview, ticket list with points, build order, open items |
| `NN-<epic>-tickets.md` | The developer building it | Build steps, acceptance criteria, edge cases, Depends on / Blocks |
| `NN-<epic>-design.md` | "Why is it like this?" | Architecture, rejected alternatives, measured evidence, non-developer follow-ups, open questions |

Alongside them: `reference/` for data acquired during discovery, `superseded/` for earlier drafts. **If a developer does not need it to build or verify the ticket, it belongs in the design doc** - a ticket carries a short pointer, not the argument. What belongs in the ticket despite reading like context: a gotcha that will cause a defect, and a constraint the implementation must preserve.

**Run a reconciliation pass before anyone else reads the plan.** The tickets file stays current because that is where the work happens; the summary and design rot behind it. Mechanical checks: titles and points match between tickets file and summary; every ticket reference resolves; every dependency points earlier; internal links resolve. Read for: decisions reversed, questions answered, numbers superseded, terminology retired.

**Terminology is a real pass.** A retired name surviving in new prose, or one phrase meaning two things, is cheap while drafting and expensive once a developer reads the wrong meaning. Rule for renames: new names use the current term; existing schema and code keep their real names verbatim - write that rule down once.

## The epic ticket

- Title: `<Theme>: <Deliverable>` - e.g. `Community: Foundation`; the theme usually matches the component.
- Component and scrum team on the epic **and** every child. No story points on the epic.
- The description carries **the shape of the work**: what the epic is and the constraints that forced the design, the build order, the open items, and a pointer to the design document attached to the epic. Deliberately **not**: the ticket list (Jira renders children itself), anything point-in-time ("as of" tables, readiness status), or ticket-level build detail.
- Do not mingle planned work into a catch-all epic accumulating spikes - a planned epic has a shape (build order, milestone, meaningful point total) and merging erases all three.

## Moving an epic into Jira

1. Draft in the tickets doc - number, type, summary, description, in the style they carry into Jira.
2. Discuss and revise in place; the doc is the single source of truth while the plan is in flux.
3. 🔴 Explicit sign-off (see write-ticket) - then create, epic first, then children with all fields set (mechanics: write-ticket's jira-reference.md).
4. Record the keys back into the summary and tickets files as each is created.

**A ticket in Jira has no header.** The tickets file opens with context governing every ticket; in Jira each ticket is standalone. Push load-bearing header lines ("every ticket targets the sandbox") down into the tickets they govern - repetition is cheaper than one wrong environment. Document furniture is not copied at all.

**Links the reader cannot open:** repo paths survive as plain text and stay useful; links to planning documents become "see the design document attached to the epic".

**The Jira-bound copies.** Moving an epic in produces two more files beside the three planning documents - edited copies, saved for review rather than pasted and lost: `NN-<epic>-epic-description.md` (the epic description exactly as set via the API) and `NN-<epic>-epic-details.md` (the design doc edited to stand alone in Jira - local links removed, cross-references named in prose).

**Lifecycle:** the local documents outlive creation only until grooming. Once the team is satisfied with the tickets and epics, the local files can be deleted - the longer documents live on as attachments to the epic, which from then on is the record.

## Part 3 - across epics

- One epic is right up to roughly **30 points**. Past that, split along **delivery seams** a stakeholder would recognise ("Identity/SSO", "Data Migration"), not technical layers. **Group into epics last** - grouping depends on the final shape of the list.
- **A "Foundations" epic first** when several later epics depend on the same groundwork - also the fix for circular dependencies between epics: extract the shared part into a third.
- **"Do it in production" is a seam too.** Where something outside engineering gates the real environment, put every one-time production step in its own epic - otherwise feature epics can never close and the release gate hides as the last ticket of an epic named for something else. The test the split is clean: **the production epic needs no new code** - each ticket re-runs a module or re-applies a recorded decision. If one has to build something, the original ticket did the work by hand where it should have written re-runnable code.
- `00-overview.md` is the programme document: what we are building, an epic map with dependencies (epic / team / points / depends-on), every ticket grouped by epic one line each, how the work progresses, cross-team dependencies and risks. Number epic files in execution order; renumber rather than append.
- Cross-epic ordering (including the honest "which epic first" under limited capacity, with the argument for each option) belongs in the overview. Cross-epic references name the epic in local docs ("foundation ticket 2") but name the *work* in Jira ("handled in the App Identity epic") - and they stay prose after keys exist; there is no backfilling pass.
- **Mark tickets whose premise is under negotiation** (a vendor might take the work) as tentative and blocked pending the answer, saying what changes under each outcome - and mark only what actually depends on it; a blanket label hides the parts safe to start.
- Rough programme sizing: XS 0-10 · S 10-30 · M 30-60 · L 60-100 · XL 100-200 · 2XL 200+ points, ~$750/point (Sept 2025).

## Writing style

Everything the write-ticket skill says about voice applies to the planning documents too: plain declaratives, no selling, 🔴/⚠️ reserved for real traps, and **no hard-wrapped markdown** - one long line per paragraph, list item and table row.
