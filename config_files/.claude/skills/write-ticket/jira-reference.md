# Jira creation mechanics

Point-in-time reference for creating tickets via the Jira API. Field and option ids drift between projects and over time - **confirm ids with a read call before any bulk create**, and treat the values below as last-verified snapshots, not constants.

## Search the project before creating anything

A locally drafted plan has no idea what is already in Jira. Before creating: list the children of any epic in the area (`parent = <EPIC>`), and search the project for the nouns in your summaries. For each hit decide explicitly - **update it in place** (usually right when someone is actively working on it: your content is better, their ticket has the history and assignee), **close it as superseded**, or **drop the duplicate from your plan**.

⚠️ Existing spikes are scope you have not planned. Open questions someone else raised are either in your work or deliberately out of it; "we never noticed them" is not a third option.

## Fields (verified against `APP`, 2026-08-25)

**Only `summary` is genuinely required** - everything else fails silently when missing. Set fields deliberately; nothing will catch you.

| Field | Value | Field id |
|---|---|---|
| Project | Comoto App (`APP`) | - |
| Issue type | `Epic` 10000 · `Tech Task` 3 · `Inquiry` 10300 | - |
| Component | On the epic **and** every child | `components` |
| Scrum Team | Rohan = option 13538 | `customfield_14560` |
| Story Points | Tech Tasks and Inquiries - never the epic | `customfield_10004` |
| QA Risk | Medium = option 12330 | `customfield_14594` |
| Priority | Standard = 4 | `priority` |
| Parent epic | The epic's key | `parent` |

Known `APP` components: Content 16797, Community 16866, Events Hub 16867. A new product area needs its component created first.

**Prompt for the values that vary.** Project, component, scrum team and QA risk change per feature - ask rather than inheriting them from the last plan.

## Quirks

- ⚠️ `UAT` (`customfield_11000`) is not on the APP screen - do not set it.
- ⚠️ Both `parent` and `Epic Link` (`customfield_10007`) exist. Set `parent` - verified working - and confirm the child actually appears under the epic.
- ⚠️ Tech Tasks auto-assign to the reporter, and `assignee: null` is ignored at creation. Clear it with a follow-up edit. Inquiries do not do this.
- Descriptions are Markdown (`contentFormat: "markdown"`, 32,000 character limit). Tables, fenced code, headings, links, nested lists and emoji all convert. One quirk: bold wrapping a code span truncates at the backtick - write `**Where this lives.** \`Module.Name\``, never `**Where this lives \`Module.Name\`**`.
- Created tickets land in the workflow's default status (Grooming in `APP`) - **leave them there**. The team evaluates each ticket and its points together before moving it to Queued; creation-time points are the plan's proposal.

## Record keys back immediately

Write each issue key into the plan document as it is created, not in a batch at the end - a create loop that fails partway otherwise leaves the only record in tool output.

## Superseding an existing ticket

When an existing ticket duplicates one you are creating and updating in place is not wanted, do all three: **link** with a `Duplicate` link, **comment** saying where the work went (naming each new ticket if the old one's intent spans several), and **transition** it closed with the resolution set.

🔴 **Never close a ticket someone is actively working on without the owner's explicit say-so**, even when the plan clearly supersedes it.
