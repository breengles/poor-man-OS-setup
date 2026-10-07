export const meta = {
  name: 'autoresearch-propose',
  description: 'Propose, judge, and build autoresearch experiments for one tick (run it through /autoresearch)',
  phases: [{ title: 'Propose' }, { title: 'Judge' }, { title: 'Build' }],
}

// One run per tick. ar.py owns the ledger, every status change, and every git ref under the campaign. Agents only
// propose, edit code in an experiment worktree, and write sbatch scripts. The fleet cap is three Opus agents in
// flight: three proposers, then one judge, then builders three at a time, then one Sonnet agent that abandons the
// experiments of failed builders.

// Saving the script makes it a slash command too, and a bare /autoresearch-propose has no campaign to work on.
if (!args || !Number.isInteger(args.slots) || args.slots < 1) {
  return { error: 'no args.slots: start this through the autoresearch skill tick, which computes the free slots' }
}

const CHUNK = 3
const AR = `cd ${args.repo} && uv run --script ~/.claude/skills/autoresearch/scripts/ar.py`
const CHAMPION = `autoresearch/${args.campaign}/champion`
const strings = { type: 'array', items: { type: 'string' } }

const PROPOSALS = {
  type: 'object',
  properties: {
    proposals: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          hypothesis: { type: 'string' },
          change: { type: 'string' },
          files: strings,
          rationale: { type: 'string' },
        },
        required: ['hypothesis', 'change', 'files', 'rationale'],
      },
    },
  },
  required: ['proposals'],
}
const VERDICT = {
  type: 'object',
  properties: {
    picked: { type: 'array', items: { type: 'integer' } },
    rejected: {
      type: 'array',
      items: {
        type: 'object',
        properties: { index: { type: 'integer' }, reason: { type: 'string' } },
        required: ['index', 'reason'],
      },
    },
  },
  required: ['picked', 'rejected'],
}
const BUILD = {
  type: 'object',
  properties: {
    exp: { type: 'string' },
    job: { type: 'string' },
    error: { type: 'string' },
    notes: {
      type: 'array',
      items: {
        type: 'object',
        properties: { kind: { type: 'string', enum: ['env', 'dead-end'] }, note: { type: 'string' } },
        required: ['kind', 'note'],
      },
    },
  },
  required: ['notes'],
}
const ABANDONED = { type: 'object', properties: { abandoned: strings }, required: ['abandoned'] }

const run = (task, label, phase, schema, model = 'opus') => agent(task, { label, phase, schema, model })

const campaignLines = [
  `Campaign: ${args.campaign}`,
  `Project root: ${args.repo}`,
  `Campaign directory: ${args.campaignDir}`,
  `Goal: ${args.goal}`,
  `Target metric: ${args.metric}, direction ${args.direction}, a new champion must win by more than ${args.minDelta}`,
  `Scope globs (the only files an experiment may change): ${args.scope.join(', ')}`,
  `Champion branch: ${CHAMPION}. Experiment branches: autoresearch/${args.campaign}/<exp>.`,
  `ar.py: \`${AR} <command> ... --json\`. Ignore warnings on stderr.`,
].join('\n')

const ANGLES = [
  ['architecture', 'model architecture: layers, attention, normalization, embeddings, heads, and model size'],
  [
    'optimization',
    'optimization and schedule: optimizer, learning rate and its schedule, warmup, batch size, precision',
  ],
  ['data', 'data and regularization: data mix, filtering, augmentation, dropout, weight decay, label smoothing'],
]

function proposeTask(angle) {
  return [
    `You propose experiments for an autoresearch campaign. Your angle is ${angle}.`,
    '',
    campaignLines,
    '',
    'Read before you propose:',
    `1. \`${AR} status ${args.campaign} --json\`: the champion and every past experiment with its hypothesis and result.`,
    `2. ${args.campaignDir}/notes.md: user steering and facts that builders learned. Follow the steering.`,
    `3. The champion code in scope: \`git -C ${args.repo} show ${CHAMPION}:<path>\` and`,
    `   \`git -C ${args.repo} ls-tree -r --name-only ${CHAMPION}\`.`,
    `4. If the exact settings of a past run matter, read its MLflow params. The database is \`mlflow_db\` in`,
    `   ${args.campaignDir}/campaign.toml. Open it read-only, and find runs by the tag autoresearch.exp=<exp>.`,
    '',
    'Consider combining finished winners that are not in the champion lineage. A winner is a done experiment with',
    'verdict champion, or with a metric close to the champion. It is outside the lineage when',
    `\`git -C ${args.repo} merge-base --is-ancestor autoresearch/${args.campaign}/<exp> ${CHAMPION}\` fails.`,
    '',
    `Return up to ${args.slots} proposals. Each one is a single change that you can test with one training run.`,
    'Do not repeat the hypothesis of a past experiment. Every file in `files` must match a scope glob.',
    'For each proposal give the hypothesis in one sentence, the concrete change, the files, and the rationale.',
    '',
    'This is read-only work. Do not edit files, do not change git refs, and run no ar.py command other than status.',
    'Run no training, tests, or project code on this node: it is a login node.',
  ].join('\n')
}

function judgeTask(proposals) {
  return [
    `You judge proposals for an autoresearch campaign. Pick at most ${args.slots} of them.`,
    '',
    campaignLines,
    '',
    `Read \`${AR} status ${args.campaign} --json\` and ${args.campaignDir}/notes.md first.`,
    'Reject a proposal that repeats the hypothesis of a past experiment, or that duplicates a proposal you picked.',
    'Reject a proposal that changes a file outside the scope globs, or that goes against the steering in notes.md.',
    'From the rest, pick the ones with the best expected gain per GPU-hour, and prefer variety across the angles.',
    '',
    'Return `picked` as proposal indexes, and `rejected` with an index and a one-line reason for each rejection.',
    'This is read-only work. Do not edit files, and run no ar.py command other than status.',
    '',
    'Proposals:',
    JSON.stringify(
      proposals.map((p, index) => ({ index, ...p })),
      null,
      2,
    ),
  ].join('\n')
}

function abandonTask(failures) {
  return [
    'You clean up after failed builders of an autoresearch campaign. Run only the commands below.',
    '',
    `1. Run \`${AR} status ${args.campaign} --json\`.`,
    '2. For each failure below, find the experiment with status `building` whose id is `exp`. When `exp` is null,',
    '   find the one with status `building` whose hypothesis is `hypothesis`. Skip a failure with no such experiment.',
    `3. For each experiment you found, run \`${AR} abandon ${args.campaign} <exp> --reason <reason> --json\`, with the`,
    '   reason of its failure shell-quoted.',
    '',
    'Change no file and no git ref. Return the IDs that you abandoned.',
    '',
    'Failures:',
    JSON.stringify(failures, null, 2),
  ].join('\n')
}

function buildTask(proposal) {
  return [
    'You build one experiment for an autoresearch campaign and submit its smoke job.',
    '',
    campaignLines,
    `Reference sbatch script (path in the project): ${args.referenceSbatch}`,
    `How to shrink a run for a smoke: ${args.smokeHint}`,
    '',
    'Proposal:',
    JSON.stringify(proposal, null, 2),
    '',
    'Steps:',
    `1. Run \`${AR} new ${args.campaign} --hypothesis <hypothesis> --json\`, with the hypothesis shell-quoted. It returns`,
    '   {exp, worktree, dir}. If it fails, stop and return the error.',
    '2. Make the change in the worktree. Put every part of the change in files that match the scope globs. ar.py',
    '   crashes the experiment and submits no job when a commit touches any other path.',
    '   The project already logs the hyperparameters and config of every run to MLflow as run params. Keep it working.',
    '3. Commit in the worktree with `git -C <worktree> commit`, on the experiment branch that is checked out there.',
    '   Write the subject imperative and lowercase, about 50 characters, with no type prefix such as `feat:`.',
    '   Commit every edit: ar.py crashes the experiment when the worktree has uncommitted or untracked files.',
    '4. Write <dir>/smoke.sbatch and <dir>/full.sbatch, based on the reference sbatch script. The scripts set only',
    '   these, and no hyperparameter override:',
    '   - SLURM resources. The full script keeps the reference resources.',
    '   - In the smoke script only, the shrink from the smoke hint.',
    `   - The MLflow tags autoresearch.campaign=${args.campaign}, autoresearch.exp=<exp>, and autoresearch.kind=smoke`,
    '     or full, through the mechanism the project already has for run tags. Read the training code to find it.',
    '   - The training checkpoint and output directory, set to <dir> (absolute). ar.py removes the worktree when the',
    '     experiment ends, so checkpoints in the worktree would be lost.',
    '   - The switch that turns on MLflow param logging, if the project needs one.',
    '   Leave out --chdir and --output: ar.py sets them, so the job runs in the worktree and logs to <dir>.',
    `5. Run \`${AR} smoke ${args.campaign} <exp> --json\`. It returns {job}, or an error.`,
    `6. For each fact that later builders need, run \`${AR} note ${args.campaign} --kind env|dead-end --text <fact>\`.`,
    '   Use env for how the project or cluster behaves, and dead-end for an approach that failed and why.',
    '',
    'Rules:',
    '- Run no training, tests, or project code on this node: it is a login node. GPU work goes only through sbatch,',
    '  and only ar.py submits it.',
    `- Never edit ${args.campaignDir}/ledger.json, notes.md, or campaign.toml by hand.`,
    `- Never move, reset, or delete a git ref: not ${CHAMPION}, and not any other branch. Do not push.`,
    '- Work only in your own worktree and experiment directory.',
    '',
    'Return exp, job, error (empty on success), and the notes you reported.',
  ].join('\n')
}

// Phase: Propose
const proposed = await Promise.all(
  ANGLES.map(([key, angle]) => run(proposeTask(angle), `propose-${key}`, 'Propose', PROPOSALS)),
)
const proposals = proposed.flatMap((out) => (out && out.proposals) || [])
if (!proposals.length) return { built: [], failed: [], rejected: [] }

// Phase: Judge
const verdict = await run(judgeTask(proposals), 'judge', 'Judge', VERDICT)
if (!verdict) return { error: 'judge returned no result', built: [], failed: [], rejected: [] }
const picked = [...new Set(verdict.picked)].filter((i) => proposals[i]).slice(0, args.slots)
const rejected = verdict.rejected.filter((r) => proposals[r.index]).map((r) => proposals[r.index].hypothesis)

// Phase: Build
const built = []
const failed = []
for (let start = 0; start < picked.length; start += CHUNK) {
  const chunk = picked.slice(start, start + CHUNK)
  const outs = await Promise.all(chunk.map((i) => run(buildTask(proposals[i]), `build-${i}`, 'Build', BUILD)))
  outs.forEach((out, n) => {
    const hypothesis = proposals[chunk[n]].hypothesis
    if (!out) {
      failed.push({ exp: null, hypothesis, reason: 'builder returned no result' })
    } else if (out.error || !out.job) {
      failed.push({ exp: out.exp || null, hypothesis, reason: out.error || 'no job submitted' })
    } else {
      built.push({ exp: out.exp, job: out.job })
    }
  })
}

// An experiment left building blocks the next tick until build_timeout_hours, so abandon it now. The builder that
// failed cannot be trusted to do it. ar.py refuses an experiment that is no longer building, such as one that smoke
// already crashed.
if (failed.length) await run(abandonTask(failed), 'abandon', 'Build', ABANDONED, 'sonnet')

return { built, failed, rejected }
