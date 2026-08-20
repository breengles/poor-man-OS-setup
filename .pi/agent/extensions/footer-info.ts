/**
 * Compact footer: cwd + git branch on the left, session cost, context use,
 * model, generation speed and thinking level on the right.
 *
 *   ~/poor-man-OS-setup on main        $0.00 for 012k on qwen3:30b[262k] | 47t/s | off
 *
 * Adapted from JanRocketMan/dotfiles. Differences: git only (no jujutsu),
 * cost keeps cents, ASCII separators.
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

/** Two decimals, capped at 99.99 so the field never grows past 6 cells. */
function formatCost(cost: number): string {
	return `$${Math.min(99.99, Math.max(0, cost)).toFixed(2)}`;
}

/** Always 3 digits + k, capped at 999k: 96000 -> 096k, 1500000 -> 999k. */
function formatContextK(tokens: number): string {
	const k = Math.min(999, Math.max(0, Math.round(tokens / 1000)));
	return `${k.toString().padStart(3, "0")}k`;
}

function formatWindow(window: number): string {
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

function getBranch(): string {
	try {
		const root = execSync("git rev-parse --show-toplevel 2>/dev/null", {
			timeout: 2000,
			stdio: ["ignore", "pipe", "pipe"],
		})
			.toString()
			.trim();
		if (!root || root === process.env.HOME) return "";
		const branch = execSync("git symbolic-ref --short HEAD 2>/dev/null", {
			timeout: 2000,
			stdio: ["ignore", "pipe", "pipe"],
		})
			.toString()
			.trim();
		return branch ? `on ${branch}` : "";
	} catch {
		return "";
	}
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
					let totalCost = 0;
					for (const entry of ctx.sessionManager.getBranch()) {
						if (entry.type !== "message") continue;
						if (entry.message.role !== "assistant") continue;
						totalCost += (entry.message as AssistantMessage).usage.cost.total;
					}

					const usage = ctx.getContextUsage();
					const window = usage?.contextWindow ?? contextWindow;
					const tokens = usage?.tokens ?? null;
					const tokensStr =
						tokens !== null ? formatContextK(tokens) : "???k";

					const branch = getBranch();
					const cwd = formatCwd(ctx.cwd, process.env.HOME || "");
					const left = branch ? `${cwd} ${branch}` : cwd;

					const tps = lastTps !== null ? formatTps(lastTps) : "--t/s";
					const thinking = hasReasoning ? thinkingLevel : "off";
					const right =
						`${formatCost(totalCost)} for ${tokensStr} on ` +
						`${modelId || "no-model"}${formatWindow(window)} | ${tps} | ${thinking}`;

					const leftDim = theme.fg("dim", left);
					const rightDim = theme.fg("dim", right);
					const leftW = visibleWidth(leftDim);
					const rightW = visibleWidth(rightDim);

					if (leftW + rightW <= width) {
						const pad = " ".repeat(width - leftW - rightW);
						return [truncateToWidth(leftDim + pad + rightDim, width)];
					}
					// Right block does not fit: drop it, truncate the left if needed.
					return [truncateToWidth(leftDim, width)];
				},
			};
		});
	});
}
