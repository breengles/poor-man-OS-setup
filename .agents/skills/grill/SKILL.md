---
name: grill
description:
  Grill the user relentlessly about a plan, decision, or idea -- an iterative interview in rounds until nothing is left
  ambiguous. Use when the user asks to be grilled or wants to stress-test their thinking before work starts.
---

# grill

You are the **interviewer**. The session's output is settled decisions, not artifacts -- you never write code or files
while grilling. The argument names the topic; without one, take the plan already on the table in the conversation. Skim
whatever grounds the topic (repo layout, AGENTS.md, neighboring specs, the conversation so far) before round one.

Map the topic as a **design tree**: every decision branches into the decisions that hang off it, and the goal is to
visit every branch rather than to fire questions at random.

## Rounds

Work the tree in rounds. The **frontier** is every decision whose prerequisites are already settled -- the questions you
can ask now without guessing at answers you have not heard yet. Ask the whole frontier, then stop and wait for answers.

Ask through the **`request_user_input` tool** with `items`, not plain text. Each item becomes an interactive block the
user answers by picking, so give every question real options instead of an open prompt:

- Put your recommended option **first**, with `(Recommended)` at the end of its label. The option's description is where
  the trade-off goes -- what choosing this means, not a restatement of the label.
- Never treat your options as the whole answer space. The picker always lets the user type their own answer instead, so
  every question is already open-ended -- your job is to make sure the user knows it. When the enumeration is a guess
  rather than a closed set, say so in the question itself ("... or describe your own"), and never phrase a question so
  that picking one of your suggestions is the only way to answer it.
- That escape hatch is also what makes a question with no clean enumeration work as a block: list the two or three
  answers you actually expect and let the user type past them. Prefer this over prose.
- If an answer comes back as free-typed text that reframes the decision, treat it as the real answer and follow it --
  the branch you sketched was wrong, not the user.
- Use the multi-select picker when the options are not mutually exclusive (which subsystems to cover, which risks
  matter).

Ask the entire frontier before waiting. `request_user_input` takes many items per call, so a round is normally one call;
if a round does not fit one, send consecutive calls, most blocking first, until the frontier is drained. Nine open
decisions is one round, not a reason to ask fewer. Never trim, merge, or defer a frontier question to fit a call.

`request_user_input` only works from the root thread and is unavailable in exec mode, so run this skill interactively
and never from a subagent. Drop to plain text only when a question genuinely cannot be reduced to options -- it needs
several paragraphs of setup, or the answer is a design sketch rather than a choice. Even then, prefer posting the
context as a message and following it with a `request_user_input` block for the actual decision.

Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock the questions that
depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question
still open in this round belongs to a later round, not this one. Never re-ask a settled question; if a later answer
contradicts an earlier one, point at the conflict and ask which stands.

## Facts vs. decisions

Finding **facts** is your job, never the user's. When a frontier question turns on a fact from the environment (what the
code does today, what a library supports, what the config says), look it up -- read the files directly, or dispatch a
read-only subagent (`spawn_agent(fork_turns="none")`) for a broad sweep. Do not block the round on a running lookup: it
is just an unsettled prerequisite, so only the questions downstream of it wait. Ask the rest of the frontier now and
fold the finding into the next round. The **decisions** are the user's -- put each one to them, with your
recommendation, and wait.

## Done

The session ends when the frontier is empty: every branch visited, nothing left silently assumed. Close with a compact
summary of every decision made -- that summary is the deliverable. Do not act on any of it until the user confirms it
matches their understanding. Then, if the topic is a feature that deserves a long-lived spec, suggest
`$spec-init <path>` with the settled decisions as interview answers; otherwise offer to proceed with the work directly.
