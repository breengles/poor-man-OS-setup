export const meta = {
  name: 'implement-units',
  description: 'Implement and commit tracked units one at a time (run it through /implement)',
  phases: [{ title: 'Implement' }, { title: 'Land' }],
}
// pi: send the text below this line as workflowScript, prefixed with `const args = <args JSON>;`

// One script for Claude Code's Workflow tool and pi-subagents' workflowScript. pi rejects nested async
// functions, so helpers return promises and the loop awaits at top level. Units run strictly in order
// because every implementer writes to the same working tree.
const PI = typeof runs !== 'undefined'
const say = typeof log === 'function' ? log : console.log

// Saving the script makes it a slash command too, and a bare /implement-units has no queue to run.
if (!args || !Array.isArray(args.queue)) {
  return { error: 'no args.queue: start this through the implement skill, which builds the queue' }
}

const strings = { type: 'array', items: { type: 'string' } }
const NOTES = {
  type: 'array',
  items: {
    type: 'object',
    properties: { kind: { type: 'string', enum: ['env', 'deviation', 'dead-end'] }, note: { type: 'string' } },
    required: ['kind', 'note'],
  },
}
const STATUS = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['COMPLETE', 'BLOCKED', 'NEEDS_CONTEXT'] },
    files_changed: strings,
    criteria_checked: strings,
    tests_run: { type: 'string' },
    concerns: strings,
    blocker: { type: 'string' },
    missing: { type: 'string' },
    notes: NOTES,
  },
  required: ['status', 'files_changed'],
}
const LAND = {
  type: 'object',
  properties: {
    committed: { type: 'boolean' },
    sha: { type: 'string' },
    summary: { type: 'string' },
  },
  required: ['committed', 'summary'],
}

// Writers opt out of pi's inferred acceptance gates: the implementer runs the tests and checks the criteria itself.
function step(key, agentName, phaseTitle, task, schema, opts) {
  if (PI) {
    const params = { agent: agentName, task, outputSchema: schema, context: 'fresh' }
    if (opts.writer) params.acceptance = { level: 'none', reason: 'the implementer validates its own unit' }
    return runs.run(key, params).then((r) => (r && r.ok ? r.structuredOutput || null : null))
  }
  const o = { label: key, phase: phaseTitle, schema }
  if (agentName) o.agentType = agentName
  if (opts.model) o.model = opts.model
  if (opts.effort) o.effort = opts.effort
  return agent(task, o)
}

const testLine = `Test command: ${args.testCmd || 'none known'}`
// Fixed text after the orchestrator's `text`, so a stray instruction there cannot make an implementer mark a unit
// Done before the land step.
const artifactLine = `The land step updates ${args.artifact} after you finish. Do not edit it, and do not commit.`
const list = (items) => (items.length ? items.map((s) => `- ${s}`).join('\n') : '- (none)')

function implementTask(unit, id) {
  return [
    `Implement tracked unit ${id} from ${args.artifact}.`,
    '',
    unit.text,
    unit.extraContext ? `\nAdditional context from the orchestrator:\n${unit.extraContext}` : '',
    '',
    testLine,
    artifactLine,
  ].join('\n')
}

function landTask(unit, id, files, notes) {
  return [
    `Land tracked unit ${id}. Do not change source code.`,
    '',
    '1. Check the scope. Run `git status --porcelain`. Every path in it must be an implementer file, the artifact, or a',
    '   baseline path. If any other path changed, do not commit: return committed false and name each such path.',
    `2. Update the artifact ${args.artifact}. For each of ${unit.ids.join(', ')}: set Status to Done, append a`,
    '   one-line `_Done: <what shipped>_` note to its detailed section, and delete its lines from the suggested',
    '   resolution order. Append the notes below to the `## Notes` section at the end of the artifact, verbatim.',
    '   Create the section if it is missing, and skip a note that repeats an existing entry. If the section now has',
    '   more than 40 entries, merge the ones that say the same thing. Then run `npx prettier --write --print-width 120`',
    '   on the artifact.',
    '3. Commit. Stage with `git add` on the implementer files and the artifact only, never `-A` or `.`, and never',
    '   a baseline path. Write the subject imperative and lowercase, about 50 characters, describing what changed.',
    '   No type prefix such as `fix:`, and no issue IDs.',
    '',
    'Return committed, the short sha, and a one-line summary of what shipped, or of why the commit failed.',
    '',
    'Notes:',
    notes.length ? notes.join('\n') : '- (none)',
    '',
    'Implementer files:',
    list(files),
    '',
    'Baseline `git status --porcelain` from before the run:',
    args.baseline || '(clean)',
  ].join('\n')
}

const done = []
const blocked = []
const concerns = []
const blockedIds = new Set()
const result = (stopped) => ({ done, blocked, concerns, stopped })
// Notes travel with the unit: the land step writes them only when it commits the unit, so a stopped attempt
// cannot plant a fact for later units. Blocked units and stops hand theirs to the main session.
let notes = []
function collect(out, id) {
  for (const n of (out && out.notes) || []) {
    const line = `- [${id} ${n.kind}] ${n.note}`
    if (!notes.includes(line)) notes.push(line)
  }
}
const stop = (unit, reason) => result({ ids: unit.ids, reason, notes })

for (const unit of args.queue) {
  const id = unit.ids.join('+')
  const key = id.replace(/[^A-Za-z0-9._-]/g, '-')
  const openDeps = (unit.depends || []).filter((d) => blockedIds.has(d))
  if (openDeps.length) {
    blocked.push({ ids: unit.ids, reason: `depends on blocked ${openDeps.join(', ')}` })
    unit.ids.forEach((u) => blockedIds.add(u))
    continue
  }

  say(`${id}: implementing`)
  notes = []
  const impl = await step(`impl-${key}`, 'implementer', 'Implement', implementTask(unit, id), STATUS, { writer: true })
  if (!impl) return stop(unit, 'implementer returned no status')
  collect(impl, id)
  concerns.push(...(impl.concerns || []).map((c) => `${id}: ${c}`))
  if (impl.status === 'NEEDS_CONTEXT') return stop(unit, `needs context: ${impl.missing}`)
  if (impl.status === 'BLOCKED') {
    if (impl.files_changed.length) return stop(unit, `blocked with changes left in the tree: ${impl.blocker}`)
    blocked.push({ ids: unit.ids, reason: impl.blocker, notes })
    unit.ids.forEach((u) => blockedIds.add(u))
    continue
  }

  const files = impl.files_changed
  const land = await step(`land-${key}`, PI ? 'worker' : null, 'Land', landTask(unit, id, files, notes), LAND, {
    writer: true,
    model: 'sonnet',
    effort: 'medium',
  })
  if (!land || !land.committed) {
    return stop(unit, `not committed: ${land ? land.summary : 'no result'}`)
  }
  done.push({ ids: unit.ids, sha: land.sha, summary: land.summary })
  say(`${id}: ${land.sha} ${land.summary}`)
}

return result(null)
