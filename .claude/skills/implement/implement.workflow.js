export const meta = {
  name: 'implement',
  description: 'Implement, verify, and commit tracked units one at a time',
  phases: [{ title: 'Implement' }, { title: 'Verify' }, { title: 'Land' }],
}
// pi: send the text below this line as workflowScript, prefixed with `const args = <args JSON>;`

// One script for Claude Code's Workflow tool and pi-subagents' workflowScript. pi rejects nested async
// functions, so helpers return promises and the loop awaits at top level. Units run strictly in order
// because every implementer writes to the same working tree.
const PI = typeof runs !== 'undefined'
const say = typeof log === 'function' ? log : console.log

const strings = { type: 'array', items: { type: 'string' } }
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
  },
  required: ['status', 'files_changed'],
}
const VERDICT = {
  type: 'object',
  properties: {
    pass: { type: 'boolean' },
    criteria: {
      type: 'array',
      items: {
        type: 'object',
        properties: { id: { type: 'string' }, met: { type: 'boolean' }, evidence: { type: 'string' } },
        required: ['id', 'met', 'evidence'],
      },
    },
    tests: { type: 'string' },
    gaps: strings,
  },
  required: ['pass', 'criteria', 'gaps'],
}
const LAND = {
  type: 'object',
  properties: {
    committed: { type: 'boolean' },
    sha: { type: 'string' },
    summary: { type: 'string' },
    unexpected: strings,
  },
  required: ['committed', 'summary', 'unexpected'],
}

// Writers opt out of pi's inferred acceptance gates: the verifier stage below is the gate.
function step(key, agentName, phaseTitle, task, schema, opts) {
  if (PI) {
    const params = { agent: agentName, task, outputSchema: schema, context: 'fresh' }
    if (opts.writer) params.acceptance = { level: 'none', reason: 'the implement workflow verifies each unit itself' }
    return runs.run(key, params).then((r) => (r && r.ok ? r.structuredOutput || null : null))
  }
  const o = { label: key, phase: phaseTitle, schema }
  if (agentName) o.agentType = agentName
  if (opts.model) o.model = opts.model
  if (opts.effort) o.effort = opts.effort
  return agent(task, o)
}

const testLine = `Test command: ${args.testCmd || 'none known'}`
const list = (items) => (items.length ? items.map((s) => `- ${s}`).join('\n') : '- (none)')

function implementTask(unit, id) {
  return [
    `Implement tracked unit ${id} from ${args.artifact}.`,
    '',
    unit.text,
    unit.extraContext ? `\nAdditional context from the orchestrator:\n${unit.extraContext}` : '',
    '',
    testLine,
  ].join('\n')
}

function verifyTask(unit, id, files) {
  return [
    `Verify tracked unit ${id} from ${args.artifact} against its acceptance criteria.`,
    '',
    'Files the implementer reports changing:',
    list(files),
    '',
    unit.text,
    '',
    testLine,
  ].join('\n')
}

function repairTask(unit, id, files, gaps) {
  return [
    `An independent verifier found that tracked unit ${id} does not meet its acceptance criteria yet.`,
    'Fix only these gaps. The rest of the change stands.',
    '',
    'Gaps:',
    list(gaps),
    '',
    'Files changed so far:',
    list(files),
    '',
    unit.text,
    '',
    testLine,
  ].join('\n')
}

function landTask(unit, id, files) {
  return [
    `Land tracked unit ${id}. Do not change source code.`,
    '',
    '1. Scope check. Run `git status --porcelain`. Every changed path must be an implementer file below or the',
    '   artifact, apart from the pre-existing changes in the baseline below. If any other path changed, or none of',
    '   the implementer files changed, stop here: return committed=false and list those paths in `unexpected`.',
    `2. Update the artifact ${args.artifact}. For each of ${unit.ids.join(', ')}: set Status to Done, append a`,
    '   one-line `_Done: <what shipped>_` note to its detailed section, and delete its lines from the suggested',
    '   resolution order. Then run `npx prettier --write --print-width 120` on the artifact.',
    '3. Commit. Stage with `git add` on the implementer files and the artifact only, never `-A` or `.`, and never',
    '   a baseline path. Write the subject imperative and lowercase, about 50 characters, describing what changed.',
    '   No type prefix such as `fix:`, and no issue IDs.',
    '',
    'Return committed, the short sha, a one-line summary of what shipped, and `unexpected`.',
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
const stop = (unit, reason) => result({ ids: unit.ids, reason })

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
  const impl = await step(`impl-${key}`, 'implementer', 'Implement', implementTask(unit, id), STATUS, { writer: true })
  if (!impl) return stop(unit, 'implementer returned no status')
  concerns.push(...(impl.concerns || []).map((c) => `${id}: ${c}`))
  if (impl.status === 'NEEDS_CONTEXT') return stop(unit, `needs context: ${impl.missing}`)
  if (impl.status === 'BLOCKED') {
    if (impl.files_changed.length) return stop(unit, `blocked with changes left in the tree: ${impl.blocker}`)
    blocked.push({ ids: unit.ids, reason: impl.blocker })
    unit.ids.forEach((u) => blockedIds.add(u))
    continue
  }

  let files = impl.files_changed
  let verdict = await step(`verify-${key}-1`, 'verifier', 'Verify', verifyTask(unit, id, files), VERDICT, {})
  if (!verdict) return stop(unit, 'verifier returned no verdict')
  if (!verdict.pass) {
    say(`${id}: criteria unmet, one repair round`)
    const repair = repairTask(unit, id, files, verdict.gaps)
    const fix = await step(`repair-${key}`, 'implementer', 'Implement', repair, STATUS, { writer: true, model: 'opus' })
    if (!fix || fix.status !== 'COMPLETE') {
      return stop(unit, `repair did not complete: ${fix ? fix.blocker || fix.missing : 'no status'}`)
    }
    files = [...new Set([...files, ...fix.files_changed])]
    verdict = await step(`verify-${key}-2`, 'verifier', 'Verify', verifyTask(unit, id, files), VERDICT, {})
    if (!verdict || !verdict.pass) {
      return stop(unit, `criteria still unmet after repair: ${verdict ? verdict.gaps.join('; ') : 'no verdict'}`)
    }
  }

  const land = await step(`land-${key}`, PI ? 'worker' : null, 'Land', landTask(unit, id, files), LAND, {
    writer: true,
    effort: 'low',
  })
  if (!land || !land.committed) {
    return stop(unit, `not committed: ${land ? land.unexpected.join(', ') || land.summary : 'no result'}`)
  }
  done.push({ ids: unit.ids, sha: land.sha, summary: land.summary })
  say(`${id}: ${land.sha} ${land.summary}`)
}

return result(null)
