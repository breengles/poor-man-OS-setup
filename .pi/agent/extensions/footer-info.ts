/**
 * Compact footer: cwd + git branch, sync (ahead/behind) and status on the
 * left, context use, model (with its window and thinking effort) and
 * generation speed on the right.
 *
 *    ~/poor-man-OS-setup main ↑2↓1~2?1           ▓░░░░░░░░░ 7% (12k) qwen3:30b[262k, high] | 47t/s
 *
 * Adapted from JanRocketMan/dotfiles. Differences: git only (no jujutsu) with a
 * colored short status; ASCII separators; everything is space-padded so it does
 * not jitter; context is space-padded (no leading zeros) and sits after the bar
 * and percent; the thinking effort lives in the model bracket; session cost
 * removed.
 */

import { execSync } from "node:child_process";
import { isAbsolute, relative, resolve, sep } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// Fixed-width formatters. The footer is one line and repaints on every render,
// so a field that changes width makes the whole right block jitter.

/** Always 2 digits, capped at 99: 4 -> 04, 47 -> 47, 150 -> 99. */
function formatTps(tps: number): string {
	const clamped = Math.min(99, Math.max(0, Math.round(tps)));
	return `${clamped.toString().padStart(2, "0")}t/s`;
}

/**
 * Context tokens used, as a fixed 4-cell field, space-padded with no leading
 * zeros: 12000 -> " 12k", 900 -> "  1k", 1500000 -> "999k". Space padding
 * (instead of zero padding) keeps the field the same width as the count grows,
 * so the right block does not jitter between repaints.
 */
function formatContextPlain(tokens: number): string {
	const k = Math.min(999, Math.max(0, Math.round(tokens / 1000)));
	return `${k.toString().padStart(3, " ")}k`;
}

/** Percentage of context window used. */
function formatPct(tokens: number, window: number): string {
	if (window <= 0) return "??%";
	const pct = Math.min(100, Math.max(0, (tokens / window) * 100));
	return `${Math.round(pct)}%`;
}

/** Progress bar for context usage. Width in cells. */
function formatProgressBar(tokens: number, window: number, width: number, theme: any): string {
	if (window <= 0 || tokens === null) return " ".repeat(width);
	const pct = Math.min(1, Math.max(0, tokens / window));
	const filledWidth = Math.round(pct * width);
	const emptyWidth = width - filledWidth;

	// Semantic theme keys, not raw color names: theme.fg() only knows the keys in
	// the theme JSON, and throws on anything else.
	let color = "success";
	if (pct >= 0.95) color = "error";
	else if (pct >= 0.8) color = "warning";

	const filled = theme.fg(color, "█".repeat(filledWidth));
	const empty = theme.fg("dim", "░".repeat(emptyWidth));
	return filled + empty;
}

/**
 * Model-meta bracket: "[262k]", or "[262k, high]" when the model supports
 * reasoning and `thinking` is the active effort (moved here from the old
 * trailing "| <effort>" slot). Skips the window when it is unknown (0).
 */
function formatWindow(window: number, thinking: string, hasReasoning: boolean): string {
	const parts: string[] = [];
	if (window > 0) {
		if (window >= 1_000_000) parts.push(`${(window / 1_000_000).toFixed(0)}m`);
		else if (window >= 1_000) parts.push(`${Math.round(window / 1_000)}k`);
		else parts.push(`${window}`);
	}
	if (hasReasoning) parts.push(thinking);
	return parts.length ? `[${parts.join(", ")}]` : "";
}

function formatCwd(cwd: string, home: string): string {
	const rel = relative(resolve(home), resolve(cwd));
	const inside =
		rel === "" ||
		(rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel));
	if (!inside) return cwd;
	return rel === "" ? "~" : `~${sep}${rel}`;
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

	pi.on("session_start", (_event, ctx) => {
		if (ctx.model) {
			const model = ctx.model as any;
			modelId = model.id || "";
			contextWindow = model.contextWindow || 0;
			hasReasoning = !!model.reasoning || !!model.compat?.thinkingFormat;
		}
		thinkingLevel = pi.getThinkingLevel();

		ctx.ui.setFooter((tui, theme, _footerData) => {
			renderRequester = tui;
			return {
				invalidate() {},
				render(width: number): string[] {
					const usage = ctx.getContextUsage();
					const window = usage?.contextWindow ?? contextWindow;
					const tokens = usage?.tokens ?? null;

					// Bar first, then percent, then the fixed-width token count.
					const tokensStr =
						tokens !== null
							? `${formatProgressBar(tokens, window, 10, theme)} ${formatPct(tokens, window)} (${formatContextPlain(tokens)})`
							: `${" ".repeat(10)} ??% (???k)`;

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
					const bracket = formatWindow(window, thinkingLevel, hasReasoning);
					const right =
						`${tokensStr} ` +
						`${modelId || "no-model"}${bracket} | ${tps}`;

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
