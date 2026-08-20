/**
 * /context -- show pi's live system prompt and the resources it loaded
 * (context files, skills, tools) in a scrollable pane, without leaving the TUI.
 *
 * Adapted from the claude-compat extension in JanRocketMan/dotfiles; the
 * nanobox sandbox shim that shipped alongside it is Linux-only and dropped.
 */

import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";
import { matchesKey, wrapTextWithAnsi } from "@earendil-works/pi-tui";

const VISIBLE_LINES = 24;

function serialize(value: unknown): string {
	const seen = new WeakSet<object>();
	return (
		JSON.stringify(
			value,
			(_key, item: unknown) => {
				if (typeof item === "bigint") return item.toString();
				if (typeof item !== "object" || item === null) return item;
				if (seen.has(item)) return "[Circular]";
				seen.add(item);
				return item;
			},
			2,
		) ?? "undefined"
	);
}

function section(title: string, content: string): string {
	return [`===== ${title} =====`, content || "(empty)"].join("\n");
}

class ContextViewer implements Component {
	private offset = 0;
	private lines: string[] = [];

	constructor(
		private readonly tui: TUI,
		private readonly theme: Theme,
		private readonly report: string,
		private readonly close: () => void,
	) {}

	handleInput(data: string): void {
		if (
			matchesKey(data, "escape") ||
			matchesKey(data, "ctrl+c") ||
			data === "q"
		) {
			this.close();
			return;
		}

		const maxOffset = Math.max(0, this.lines.length - VISIBLE_LINES);
		if (matchesKey(data, "up")) this.offset--;
		if (matchesKey(data, "down")) this.offset++;
		if (matchesKey(data, "pageUp")) this.offset -= VISIBLE_LINES;
		if (matchesKey(data, "pageDown")) this.offset += VISIBLE_LINES;
		if (matchesKey(data, "home")) this.offset = 0;
		if (matchesKey(data, "end")) this.offset = maxOffset;

		this.offset = Math.max(0, Math.min(maxOffset, this.offset));
		this.tui.requestRender();
	}

	render(width: number): string[] {
		this.lines = this.wrap(width);
		const maxOffset = Math.max(0, this.lines.length - VISIBLE_LINES);
		this.offset = Math.min(this.offset, maxOffset);
		const last = Math.min(this.offset + VISIBLE_LINES, this.lines.length);

		return [
			this.theme.fg("accent", this.theme.bold("pi context inspector")),
			...this.lines.slice(this.offset, last),
			this.theme.fg(
				"dim",
				`${this.offset + 1}-${last} of ${this.lines.length} | up/down/PgUp/PgDn scroll | Home/End | q/Esc close`,
			),
		];
	}

	invalidate(): void {}

	private wrap(width: number): string[] {
		const contentWidth = Math.max(20, width);
		return this.report.split("\n").flatMap((line) => {
			if (!line) return [""];
			return wrapTextWithAnsi(line, contentWidth);
		});
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("context", {
		description: "Inspect pi's current system prompt and loaded resources",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("/context requires interactive mode", "error");
				return;
			}

			const options = ctx.getSystemPromptOptions();
			// Context files and skills are objects; print only their identity so
			// the report stays readable -- the prompt itself already has the text.
			const summary = {
				...options,
				contextFiles: options.contextFiles?.map((file) => file.path),
				skills: options.skills?.map((skill) => skill.description),
			};
			const report = [
				section("system prompt", ctx.getSystemPrompt()),
				section("prompt inputs and loaded resources", serialize(summary)),
			].join("\n\n");

			await ctx.ui.custom<void>((tui, theme, _keybindings, done) => {
				return new ContextViewer(tui, theme, report, () => done());
			});
		},
	});
}
