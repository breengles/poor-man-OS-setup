---
name: report
description:
  Build an interactive report of what the user asks for -- a published Claude Code Artifact, or a local HTML file when
  the report holds user data or other sensitive content
argument-hint: "[what to report on] [--local]"
---

# report

Build one interactive page that answers the request in `$ARGUMENTS`. Without an argument, take the subject from the
conversation so far. If the subject or its scope is still unclear, ask before you gather anything.

## Gather

Collect the facts first: run the queries, read the files, call the tools. Every number and claim on the page must come
from something you read in this session. Never invent or extrapolate data to fill a chart. If a source fails, say so on
the page instead of hiding the gap.

## Decide where the page goes

Classify the gathered content before you write a single line of HTML. The page is **sensitive** when it contains any of:

- Data about real people: names, emails, user IDs, phone numbers, addresses, account or payment details, user-generated
  content, chat or meeting transcripts, support tickets
- Secrets: tokens, keys, passwords, connection strings, session cookies, signed URLs
- Internal infrastructure: hostnames, IPs, internal URLs, cluster or bucket paths, unreleased product details
- Business data from company systems: revenue, user counts, experiment results, analytics exports, private repo code
- Anything the user called private, internal, or confidential, now or earlier in the session

When in doubt, treat it as sensitive. A sensitive page, or any run with `--local`, becomes a **local HTML file**. All
other pages become a **published Artifact**.

A sensitive report is **never published** -- not through the Artifact tool, a docs connector, a gist, a paste service,
or any other upload. This holds for the rest of the session, even if the user asks later. In that case, say why and
offer a new `/report` run that keeps only non-sensitive aggregates; that page goes through this check again. Never
strip sensitive fields quietly just to make a page publishable.

## Build the page

Every report is interactive. Choose the controls that fit the data:

- Tables: sort by column, filter with a search box, show row counts
- Charts: hover tooltips with exact values, a legend that toggles series
- Long content: tabs or collapsible sections, with a short summary at the top
- Detail: click a row or a chart mark to show its full record

Put the data in one `<script type="application/json" id="data">` block, and render the page from it with JavaScript.
That keeps the numbers in one place. Load the `dataviz` skill before you draw any chart. Support light and dark themes,
and make the layout work at phone width.

### Published Artifact

Follow the Artifact tool's own flow: `quickstart` with `intent: "other"`, then the design guidance it returns. Write the
file in the scratchpad directory, then publish it with a short `description` and an `icon`. Reply with the link.

### Local HTML file

- One self-contained `.html` file. Inline all CSS and JS, and draw charts as inline SVG. The page must make **no network
  request** at all -- no CDN script, no web font, no remote image, no analytics. Sensitive data must not leak through a
  request referrer, and the file must open offline.
- Load the `artifact-design` skill for design guidance, but ignore its publish and runtime-capability parts.
- Save it to `~/reports/<YYYY-MM-DD>-<slug>.html`, never inside a git repository, because a later commit could pick it
  up. Create the directory with mode `700` and the file with mode `600`.
- On macOS, open it with `open <path>`. Elsewhere, print the path and the command to copy it to a laptop.
- Reply with the absolute path and one line that names the sensitive content which kept it local.

## Check before you finish

Open the page in a browser if a browser tool is available, and confirm that it renders without console errors and that
each control works. Without a browser, at least parse the JSON block and check the HTML for unclosed tags. For a local
file, confirm with `grep -nE 'https?://' <file>` that no external URL remains outside of plain displayed text.
