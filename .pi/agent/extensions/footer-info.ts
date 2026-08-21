/**
 * Editor metadata + single-line footer. Model info and exec time are rendered
 * inside the message box (below the input line, above its bottom border); the
 * footer keeps cwd/git/status on the left and context bar, in/out tokens and
 * generation speed on the right.
 *
 *    ─────────────────────────────────────────────
 *    > message
 *
 *      qwen3:30b[262k] | high | 1m23s
 *    ─────────────────────────────────────────────
 *    ~/poor-man-OS-setup main ↑2↓1~2?1    ▓░░░░░░░░░ 7% (↑41k ↓543) | 47t/s
 *
 * Adapted from JanRocketMan/dotfiles. Differences: git only (no jujutsu) with a
 * colored short status; ASCII separators; everything is space-padded so it does
 * not jitter; context is space-padded (no leading zeros) and sits after the bar
 * and percent; the thinking effort lives in the model bracket; session cost
 * removed. Model info and exec time moved from the footer into the message box.
 */

import { execSync } from "node:child_process";
import { isAbsolute, relative, resolve, sep } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type Theme,
	type ThemeColor,
} from "@earendil-works/pi-coding-agent";
import { stripTerminalSequences, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// Fixed-width formatters. The footer repaints on every render, so a field that
// changes width makes the right block jitter.

/** Always 2 digits, capped at 99: 4 -> 04, 47 -> 47, 150 -> 99. */
function formatTps(tps: number): string {
	const clamped = Math.min(99, Math.max(0, Math.round(tps)));
	return `${clamped.toString().padStart(2, "0")}t/s`;
}

/**
 * Context tokens used: (↑input ↓output)
 * e.g. (↑41k ↓543)
 */
function formatContextTokens(input: number, output: number): string {
	const formatK = (n: number) => {
		if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}m`;
		if (n >= 1_000) return `${Math.round(n / 1000)}k`;
		return `${n}`;
	};

	return `(↑${formatK(input)} ↓${formatK(output)})`;
}

/**
 * Sum input/output tokens across assistant messages in the current session
 * branch. `ctx.getContextUsage()` only reports a total context estimate
 * (`tokens`/`contextWindow`/`percent`) and has no input/output breakdown, so
 * reading `usage.inputTokens`/`usage.outputTokens` from it always yielded 0.
 * The real per-message counts live in `usage.input`/`usage.output` (see
 * examples/extensions/custom-footer.ts).
 */
function sumSessionTokens(ctx: ExtensionContext): { input: number; output: number } {
	let input = 0;
	let output = 0;
	for (const e of ctx.sessionManager.getBranch()) {
		if (e.type === "message" && e.message.role === "assistant") {
			const m = e.message as AssistantMessage;
			input += m.usage.input;
			output += m.usage.output;
		}
	}
	return { input, output };
}

/**
 * Request duration as a fixed 6-cell field, space-padded with no leading
 * zeros: 42000 -> "  42s", 83000 -> "1m23s". Seconds stay bare ("42s"),
 * minutes use "M:SS" ("1m23s").
 */
function formatDuration(ms: number): string {
	// Capped at 99m59s so the field never outgrows its 6 cells.
	const totalSec = Math.min(99 * 60 + 59, Math.max(0, Math.round(ms / 1000)));
	const m = Math.floor(totalSec / 60);
	const s = totalSec % 60;
	const text = m > 0 ? `${m}m${s.toString().padStart(2, "0")}s` : `${s}s`;
	return text.padStart(6, " ");
}

/** Same as formatDuration but without the leading padding, for inline use. */
function formatDurationCompact(ms: number): string {
	return formatDuration(ms).trim();
}

/** Percentage of context window used. */
function formatPct(tokens: number, window: number): string {
	if (window <= 0) return "??%";
	const pct = Math.min(100, Math.max(0, (tokens / window) * 100));
	return `${Math.round(pct)}%`;
}

/** Progress bar for context usage. Width in cells. */
function formatProgressBar(tokens: number, window: number, width: number, theme: Theme): string {
	if (window <= 0 || tokens === null) return " ".repeat(width);
	const pct = Math.min(1, Math.max(0, tokens / window));
	const filledWidth = Math.round(pct * width);
	const emptyWidth = width - filledWidth;

	// Semantic theme keys, not raw color names: theme.fg() only knows the keys in
	// the theme JSON, and throws on anything else.
	let color: ThemeColor = "success";
	if (pct >= 0.95) color = "error";
	else if (pct >= 0.8) color = "warning";

	const filled = theme.fg(color, "█".repeat(filledWidth));
	const empty = theme.fg("dim", "░".repeat(emptyWidth));
	return filled + empty;
}

/**
 * Model window bracket: "[262k]", or "" when the window is unknown (0).
 * The thinking effort is rendered separately after the bracket.
 */
function formatWindow(window: number): string {
	if (window <= 0) return "";
	if (window >= 1_000_000) return `[${(window / 1_000_000).toFixed(0)}m]`;
	if (window >= 1_000) return `[${Math.round(window / 1_000)}k]`;
	return `[${window}]`;
}

function formatCwd(cwd: string, home: string): string {
	const rel = relative(resolve(home), resolve(cwd));
	const inside =
		rel === "" ||
		(rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel));
	if (!inside) return cwd;
	return rel === "" ? "~" : `~${sep}${rel}`;
}

/** Right-pad a line to `width` visible cells (ANSI-aware). */
function padRight(line: string, width: number): string {
	const w = visibleWidth(line);
	if (w >= width) return truncateToWidth(line, width, "");
	return line + " ".repeat(width - w);
}

/**
 * True for the editor's horizontal border rows: a full-width run of "─", or a
 * scroll-indicator border ("─── ↑ N more ───" / "─── ↓ N more ───"). Used to
 * find the bottom border so metadata can be inserted inside the message box.
 */
function isBottomBorderLine(line: string): boolean {
	const s = stripTerminalSequences(line);
	if (s.length === 0) return false;
	if ([...s].every((ch) => ch === "─")) return true;
	return /^─+\s*[↑↓]\s+\d+\s+more/.test(s);
}

/**
 * Branch label + a compact sync/working-tree status. Returns an empty `branch`
 * when there is no repo (or its root is $HOME). `ahead`/`behind` count commits
 * not pushed/pulled relative to the upstream (via
 * `git rev-list --left-right --count @{u}...HEAD`); both are 0 when there is
 * no upstream. `staged`/`modified`/`untracked` count working-tree changes from
 * `git status --porcelain`. Detached HEAD falls back to the short SHA. `|| true`
 * keeps a non-zero exit from one subcommand from throwing and wiping the
 * branch, too.
 */
function gitInfo(): {
	branch: string;
	ahead: number;
	behind: number;
	staged: number;
	modified: number;
	untracked: number;
} {
	const run = (cmd: string): string =>
		execSync(cmd, {
			timeout: 2000,
			stdio: ["ignore", "pipe", "pipe"],
		})
			.toString()
			.trim();
	try {
		const root = run("git rev-parse --show-toplevel 2>/dev/null || true");
		if (!root || root === process.env.HOME)
			return { branch: "", ahead: 0, behind: 0, staged: 0, modified: 0, untracked: 0 };
		let branch = run("git symbolic-ref --short HEAD 2>/dev/null || true");
		if (!branch) branch = run("git rev-parse --short HEAD 2>/dev/null || true");
		const porcelain = run("git status --porcelain 2>/dev/null || true");
		// Left count = upstream-only commits (behind), right = HEAD-only (ahead).
		const ab = run("git rev-list --left-right --count @{u}...HEAD 2>/dev/null || true");
		const [behind = 0, ahead = 0] = ab.split(/\s+/).map((n) => Number(n) || 0);
		return { branch, ahead, behind, ...summarizeStatus(porcelain) };
	} catch {
		return { branch: "", ahead: 0, behind: 0, staged: 0, modified: 0, untracked: 0 };
	}
}

/**
 * Summarize `git status --porcelain` (XY status code + filename per line) into
 * staged/modified/untracked counts. X is the index (staged) code, Y the
 * worktree (unstaged) code; "??" is untracked.
 */
function summarizeStatus(porcelain: string): {
	staged: number;
	modified: number;
	untracked: number;
} {
	let staged = 0;
	let modified = 0;
	let untracked = 0;
	for (const line of porcelain.split("\n")) {
		if (line.length < 2) continue;
		const x = line[0]; // index (staged)
		const y = line[1]; // worktree (unstaged)
		if (x === "?" && y === "?") {
			untracked++;
			continue;
		}
		if (x !== " " && x !== "?") staged++;
		if (y !== " " && y !== "?") modified++;
	}
	return { staged, modified, untracked };
}

export default function (pi: ExtensionAPI) {
	let modelId = "";
	let contextWindow = 0;
	let hasReasoning = false;
	let thinkingLevel = "off";

	// Per-turn generation speed. Each turn is one HTTP stream: `start` then
	// deltas then `done`. Tools run between turns, so tool time never lands in
	// the denominator and the number stays pure generation speed.
	let turnStartTs: number | null = null;
	let lastTps: number | null = null;
	let renderRequester: { requestRender: () => void } | null = null;

	// Whole-request timing: agent_start -> agent_settled covers the full run
	// (every turn, tool call, retry and compaction). agentStartTs is non-null
	// while a request is in flight, so render() can show a live elapsed time;
	// lastRequestMs keeps the settled duration after it completes.
	let agentStartTs: number | null = null;
	let lastRequestMs: number | null = null;

	pi.on("model_select", (event) => {
		const model = event.model as any;
		modelId = model.id || "";
		contextWindow = model.contextWindow || 0;
		hasReasoning = !!model.reasoning || !!model.compat?.thinkingFormat;
	});

	pi.on("thinking_level_select", (event) => {
		thinkingLevel = event.level;
	});

	// pi emits the stream's `start` as `message_start`, never as
	// `message_update`; `done` and `error` go straight to `message_end`.
	pi.on("message_start", (event) => {
		if (event.message.role !== "assistant") return;
		turnStartTs = Date.now();
	});

	pi.on("message_end", (event) => {
		if (event.message.role !== "assistant") return;
		const message = event.message as AssistantMessage;

		// Keep the previous measurement for failed or aborted turns.
		if (message.stopReason === "error" || message.stopReason === "aborted") {
			turnStartTs = null;
			return;
		}
		if (turnStartTs === null) return;

		const durMs = Date.now() - turnStartTs;
		const output = message.usage.output;

		// Counts thinking and tool-call argument tokens too, all of it genuine
		// streamed output. The duration floor skips the degenerate path where
		// `message_start` fires late on an empty stream and t/s blows up.
		if (output > 0 && durMs >= 50) lastTps = output / (durMs / 1000);

		turnStartTs = null;
		renderRequester?.requestRender();
	});

	pi.on("agent_start", () => {
		// A retry/compaction/follow-up run re-fires agent_start without an
		// intervening agent_settled; keep the original start so the clock
		// measures the whole request, not just the last run.
		if (agentStartTs === null) agentStartTs = Date.now();
	});

	pi.on("agent_settled", () => {
		if (agentStartTs === null) return;
		lastRequestMs = Date.now() - agentStartTs;
		agentStartTs = null;
		renderRequester?.requestRender();
	});

	pi.on("session_start", (_event, ctx) => {
		if (ctx.model) {
			const model = ctx.model as any;
			modelId = model.id || "";
			contextWindow = model.contextWindow || 0;
			hasReasoning = !!model.reasoning || !!model.compat?.thinkingFormat;
		}
		thinkingLevel = pi.getThinkingLevel();

		const thm = ctx.ui.theme;

		// Model + exec time live inside the message box, below the input line.
		class MetaEditor extends CustomEditor {
			render(width: number): string[] {
				const lines = super.render(width);
				if (lines.length < 2 || width <= 0) return lines;

				const modelInfo = `${modelId || "no-model"}${formatWindow(contextWindow)}`;
				const thinkingStr =
					hasReasoning && thinkingLevel !== "off" ? thinkingLevel : "";
				const durationStr =
					agentStartTs !== null
						? formatDurationCompact(Date.now() - agentStartTs)
						: lastRequestMs !== null
							? formatDurationCompact(lastRequestMs)
							: "--";
				const meta =
					`${thm.fg("accent", modelInfo)}` +
					(thinkingStr
						? `${thm.fg("dim", " | ")}${thm.fg("muted", thinkingStr)}`
						: "") +
					`${thm.fg("dim", " | ")}` +
					`${thm.fg("muted", durationStr)}`;
				const blank = " ".repeat(width);

				// The bottom border is the last horizontal rule; autocomplete rows
				// are appended after it and never look like a border.
				let borderIndex = -1;
				for (let i = 1; i < lines.length; i++) {
					if (isBottomBorderLine(lines[i]!)) borderIndex = i;
				}
				if (borderIndex === -1) borderIndex = lines.length - 1;

				lines.splice(borderIndex, 0, blank, padRight(meta, width));
				return lines;
			}
		}

		ctx.ui.setEditorComponent((tui, theme, kb) => {
			renderRequester = tui;
			return new MetaEditor(tui, theme, kb);
		});

		ctx.ui.setFooter((tui, theme, _footerData) => {
			renderRequester = tui;
			return {
				invalidate() {},
				render(width: number): string[] {
					if (width <= 0) return [""];

					const usage = ctx.getContextUsage();
					const window = usage?.contextWindow ?? contextWindow;
					const tokens = usage?.tokens ?? null;
					const { input, output } = sumSessionTokens(ctx);

					// Context bar + percent (first line, right-aligned).
					const barPct =
						tokens !== null
							? `${formatProgressBar(tokens, window, 10, theme)} ${formatPct(tokens, window)}`
							: `${" ".repeat(10)} ??%`;

					// Left block: cwd dim, then the branch in the accent color followed
					// by a glued run of colored symbol-number pairs (↑ ahead, ↓ behind,
					// + staged, ~ modified, ? untracked). Each pair gets its own color;
					// visibleWidth() strips the ANSI so the padding and truncation math
					// still holds.
					const cwd = formatCwd(ctx.cwd, process.env.HOME || "");
					const git = gitInfo();
					let left = theme.fg("dim", cwd);
					if (git.branch) {
						left += ` ${theme.fg("accent", git.branch)}`;
						const chips: string[] = [];
						if (git.ahead) chips.push(theme.fg("accent", `↑${git.ahead}`));
						if (git.behind) chips.push(theme.fg("muted", `↓${git.behind}`));
						if (git.staged) chips.push(theme.fg("success", `+${git.staged}`));
						if (git.modified) chips.push(theme.fg("warning", `~${git.modified}`));
						if (git.untracked) chips.push(theme.fg("error", `?${git.untracked}`));
						if (chips.length) left += ` ${chips.join("")}`;
					}

					const tps = lastTps !== null ? formatTps(lastTps) : "--t/s";
					// Right block: context bar + in/out tokens + generation speed,
					// all kept together on the single footer line.
					const right =
						`${barPct} ${formatContextTokens(input, output)} | ${tps}`;
					const rightDim = theme.fg("dim", right);

					const leftW = visibleWidth(left);
					const rightW = visibleWidth(rightDim);
					if (leftW + rightW <= width) {
						const pad = " ".repeat(width - leftW - rightW);
						return [truncateToWidth(left + pad + rightDim, width)];
					}
					// Right block does not fit: drop it, truncate the left if needed.
					return [truncateToWidth(left, width)];
				},
			};
		});
	});
}
