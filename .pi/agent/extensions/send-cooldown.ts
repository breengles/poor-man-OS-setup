/**
 * send-cooldown.ts — brief "Esc to cancel" window between pressing Enter and
 * the prompt actually reaching the model.
 *
 * On every typed free-text message in the interactive TUI, pi waits a short
 * moment before delivering the prompt. During that window the message is
 * rendered like a regular user message at the bottom of the chat with a live
 * countdown underneath; pressing Esc (or Ctrl+C) drops the message and puts it
 * back into the input box for editing. The message is neither sent nor written
 * to the session.
 *
 * Slash commands, mid-stream steering/follow-up, and non-interactive input
 * pass through untouched.
 */

import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import type { TUI } from "@earendil-works/pi-tui";
import { Box, Container, Text, matchesKey } from "@earendil-works/pi-tui";

const COOLDOWN_MS = 2500;
const TICK_MS = 100;

/** Only protect free-text prompts; slash commands are UI/skill/template directives. */
function shouldDelay(text: string): boolean {
	return text.trim().length > 0 && !text.trimStart().startsWith("/");
}

class CooldownOverlay extends Container {
	private remainingMs = COOLDOWN_MS;
	private ticker?: ReturnType<typeof setInterval>;
	private autoSend?: ReturnType<typeof setTimeout>;
	private finished = false;
	private readonly statusText: Text;

	constructor(
		private readonly tui: TUI,
		private readonly theme: Theme,
		message: string,
		private readonly done: (result: "send" | "cancel") => void,
	) {
		super();

		// Mimic a regular user message: background box + wrapped text.
		const messageBox = new Box(1, 1, (s: string) => theme.bg("userMessageBg", s));
		messageBox.addChild(new Text(theme.fg("userMessageText", message), 0, 0));
		this.addChild(messageBox);

		this.statusText = new Text("", 1, 0);
		this.addChild(this.statusText);
		this.updateStatus();

		this.ticker = setInterval(() => {
			this.remainingMs = Math.max(0, this.remainingMs - TICK_MS);
			this.updateStatus();
			tui.requestRender();
		}, TICK_MS);

		this.autoSend = setTimeout(() => this.finish("send"), COOLDOWN_MS);
	}

	private updateStatus(): void {
		const seconds = Math.ceil(this.remainingMs / 1000);
		this.statusText.setText(
			this.theme.fg("muted", "sending in ") +
				this.theme.fg("accent", `${seconds}s`) +
				this.theme.fg("muted", "  •  ") +
				this.theme.fg("warning", "Enter") +
				this.theme.fg("muted", " to send now, ") +
				this.theme.fg("warning", "Esc") +
				this.theme.fg("muted", " to cancel"),
		);
	}

	private finish(result: "send" | "cancel"): void {
		if (this.finished) return;
		this.finished = true;
		if (this.ticker) clearInterval(this.ticker);
		if (this.autoSend) clearTimeout(this.autoSend);
		this.done(result);
	}

	handleInput(data: string): void {
		if (matchesKey(data, "enter")) {
			this.finish("send");
		} else if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
			this.finish("cancel");
		}
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("input", async (event, ctx) => {
		// Terminal-only, user-typed, idle free-text only.
		if (ctx.mode !== "tui") return { action: "continue" };
		if (event.source !== "interactive") return { action: "continue" };
		if (event.streamingBehavior) return { action: "continue" }; // steer/followUp must be instant
		if (!shouldDelay(event.text)) return { action: "continue" };

		let tuiRef: TUI | undefined;
		const result = await ctx.ui.custom<"send" | "cancel">(
			(tui, theme, _keybindings, done) => {
				tuiRef = tui;
				return new CooldownOverlay(tui, theme, event.text, done);
			},
			{
				overlay: true,
				overlayOptions: { anchor: "bottom-center", width: "100%", margin: 0 },
			},
		);

		if (result === "cancel") {
			ctx.ui.setEditorText(event.text); // put it back for editing
			tuiRef?.requestRender(); // repaint so the restored text shows immediately
			return { action: "handled" }; // never sent, never recorded
		}
		return { action: "continue" };
	});
}
