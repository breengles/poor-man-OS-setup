/**
 * Single-line footer: model info on the left followed by context bar, in/out
 * tokens, all on the left.
 *
 *    qwen3:30b[262k] ▓░░░░ 7% (↑41k ↓543)
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import {
	type ExtensionAPI,
	type ExtensionContext,
	type Theme,
	type ThemeColor,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

// Fixed-width formatters. The footer repaints on every render, so a field that
// changes width makes the rest jitter.

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
 */
function formatWindow(window: number): string {
	if (window <= 0) return "";
	if (window >= 1_000_000) return `[${(window / 1_000_000).toFixed(0)}m]`;
	if (window >= 1_000) return `[${Math.round(window / 1_000)}k]`;
	return `[${window}]`;
}

export default function (pi: ExtensionAPI) {
	let modelId = "";
	let contextWindow = 0;

	// Per-turn generation speed. Each turn is one HTTP stream: `start` then
	// deltas then `done`. Tools run between turns, so tool time never lands in
	// the denominator and the number stays pure generation speed.
	let renderRequester: { requestRender: () => void } | null = null;

	pi.on("model_select", (event) => {
		const model = event.model as any;
		modelId = model.id || "";
		contextWindow = model.contextWindow || 0;
	});

	pi.on("session_start", (_event, ctx) => {
		if (ctx.model) {
			const model = ctx.model as any;
			modelId = model.id || "";
			contextWindow = model.contextWindow || 0;
		}

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

					// Context bar + percent.
					const barPct =
						tokens !== null
							? `${formatProgressBar(tokens, window, 6, theme)} ${formatPct(tokens, window)}`
							: `${" ".repeat(6)} ??%`;

					const modelInfo = `${modelId || "no-model"}${formatWindow(window)}`;

					// Left block: Model info, then context bar + tokens.
					const left =
						`${theme.fg("accent", modelInfo)} ` +
						`${theme.fg("dim", `${barPct} ${formatContextTokens(input, output)}`)}`;

					return [truncateToWidth(left, width)];
				},
			};
		});
	});
}
