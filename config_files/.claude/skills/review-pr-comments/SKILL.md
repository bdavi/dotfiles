---
name: review-pr-comments
description: Read the review comments on a pull request and present each one with the code it refers to, the reviewer's words, a check of its claims against the code, and a recommendation. Use when asked to read, go through, summarize, triage or respond to PR comments or review feedback. Covers syncing the local branch with the PR first and the presentation format. Does not change code, reply on the PR or resolve threads unless separately asked.
---

# Reviewing PR comments

The person asking wants to decide what to do about each comment without opening the PR. Every comment is presented so three things are never confused: **the code**, **what the reviewer said**, and **what you think**. Each sits in its own labelled block, and the code comes with enough surrounding lines to judge the comment without opening the file.

## 1. Make sure the local branch is the PR's branch

Comments are judged against the code they will be fixed in, so first confirm the local checkout matches the PR head.

```bash
gh pr view <n> --json headRefName,headRefOid,baseRefName,state
git fetch origin <headRefName>
git status --short --branch
git rev-parse HEAD origin/<headRefName>
```

- **Same commit, clean tree:** say so in one line and carry on.
- **Behind, clean tree:** `git merge --ff-only origin/<headRefName>`, and say what came in (`git log --oneline HEAD@{1}..HEAD`).
- **Diverged, or uncommitted changes:** stop and ask. Never reset, stash or discard to make it match.

## 2. Fetch everything, threads included

Use GraphQL, because the REST endpoints do not say whether a thread is resolved or outdated:

```bash
gh api graphql -F owner=<owner> -F repo=<repo> -F number=<n> -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviews(first: 50) { nodes { author { login } state submittedAt body } }
      comments(first: 100) { nodes { author { login } createdAt body } }
      reviewThreads(first: 100) {
        nodes {
          isResolved isOutdated path line startLine originalLine originalStartLine
          comments(first: 50) { nodes { author { login } createdAt body diffHunk originalCommit { oid } } }
        }
      }
    }
  }
}'
```

That is three sources: inline threads, review bodies (the text submitted with Approve / Request changes), and general PR comments. Read all three: a review body often carries the reviewer's overall position, and general comments are where bots and later rounds land.

- **Resolved threads** are left out unless asked for. Say how many there were.
- **Replies** stay with their thread. Show the whole exchange in order, not just the first comment.
- **Bot comments** (CI, coverage, staging links) are summarized in one line at the end, unless one says something is broken.

## 3. Pull the code each comment is about

Read it from the **local file as it stands now**, not from the comment's diff hunk. The hunk is only a few lines, and it shows the code as it was when the comment was written.

**How much to show:** the commented lines, from `startLine` to `line`, plus about 8 lines on each side. When the commented line sits inside a function of about 40 lines or fewer, show the whole function instead. When the comment is about something elsewhere ("this doesn't handle the error from X"), show that code too, as a second block with its own location.

Number every line and mark the lines the comment is attached to:

```bash
awk -v from=<a> -v to=<b> -v start=<startLine> -v end=<line> \
  'NR >= from && NR <= to { printf "%s %4d  %s\n", (NR >= start && NR <= end) ? "→" : " ", NR, $0 }' <path>
```

**Outdated comments** (`line` is null, or `isOutdated` is true) were made on code that has since changed. Find where that code is now, by searching the current file for a distinctive line from `diffHunk`, and show it there. Say plainly that the comment was on an earlier version and whether the change since then already addresses it. If the code is gone entirely, show the old hunk and label it as the old version.

## 4. Check every claim before judging it

A review comment is a set of claims about the code, and reviewers increasingly paste in findings from their own AI tools. Treat each claim the way you would treat a ticket's claims: read the code it names, follow the call chain it describes, and check third-party behaviour against the dependency's source.

Then give each comment one verdict:

- **Valid:** the problem is real and reachable.
- **Valid, not reachable today:** the code is wrong, but no current path gets there. Say why, and whether to fix it anyway.
- **Partly right:** say which part holds and which does not.
- **Not valid:** say what the reviewer missed, with the evidence. This is a reply to draft, not a fix to make.
- **A preference:** style or approach, with no defect either way. Say whether it fits the codebase's conventions.

Note any detail that is wrong even when the comment as a whole holds. For example, one of the three listed causes may not actually raise. That detail matters when drafting the reply.

## 5. Present

Order by severity, not by position in the file. When two comments are about the same underlying problem, put them next to each other and say they are linked.

Each comment uses exactly this layout. The labels are what keep the parts apart, so do not drop or merge them:

````markdown
### 1. <What the problem is, in a few words>

**Reviewer:** <login>, <inline comment | review body | PR comment>, <date>. <Resolved/outdated status, only when it is either.>

**Code:** `<path>:<start>-<end>` (→ marks the lines the comment is on)

```<language>
     12  def cancel_order(conn, %{"id" => order_id}) do
     13    result = Orders.cancel(order_id)
→    14    refund_payment(result)
     15    render_cancel_response(conn, result)
```

**Comment:**

> <The reviewer's words, verbatim, every paragraph prefixed with `>`. Replies follow in the same blockquote, each starting with **login:**.>

**Verdict:** <one of the verdicts above>. <What you checked and what you found, with file:line references.>

**Recommendation:** <What to do, concretely: the change, with a short code sketch if it helps, or the reply to give. Include anything you would do differently from the reviewer's suggestion, and why.>
````

Rules for the parts:

- **Quote, never paraphrase, inside the Comment block.** The person may want to reply word for word to what was said. Shorten only a very long pasted log or tool output, and mark the cut with `[…]`.
- **Your words never go inside the blockquote**, and the reviewer's never go outside it.
- **The code block holds only code** from the file. Notes about the code go in Verdict.
- A comment with no code location (a review body or a general comment) omits the **Code** block, unless it names specific code. In that case, show that code.

After the comments, close with:

- **Summary:** how many comments are valid, and which ones you would act on. Group the ones that share a fix.
- **Not shown:** resolved threads and bot comments, as counts.
- **The question:** what to do next. Fixing, replying and resolving are separate asks.

## Boundaries

- 🔴 **Do not change code, post replies or resolve threads as part of this.** Presenting the comments is the whole task. Each of those is a separate, explicit ask, and a reply is published under the user's name.
- When asked to draft replies, write them to a file or into the answer for the user to post. Post them yourself only when told to.
- Name reviewers by their login. Refer to them as "they" unless their pronouns are known.
