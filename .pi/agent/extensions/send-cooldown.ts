/**
 * send-cooldown.ts — brief "Esc to cancel" window between pressing Enter and
 * the prompt actually reaching the model.
 *
 * On every typed free-text message in the interactive TUI, pi waits a short
 * moment before delivering the prompt. During that window the message is
 * rendered as a user-message-style block inside the chat transcript, with a
 * live countdown underneath; pressing Esc (or Ctrl+C) drops the message and
 * puts it back into the input box for editing, pressing Enter sends it now.
 * The message is neither sent nor written to the session.
 *
 * The block is a TUI-only custom entry (pi.appendEntry +
 * pi.registerEntryRenderer), so it never reaches the LLM. The session is
 * append-only, so the entry lingers in the session file; the renderer returns
 * nothing once the deadline has passed, collapsing the block to zero height
 * both live and on reload.
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

/**
 * The TUI handle, captured from the widget factory in session_start. The entry
 * renderer receives no TUI reference of its own, so the countdown repaints
 * through this.
 */
let tuiRef: TUI | undefined;

/** The block currently on screen, so cancel/send can collapse it immediately. */
let activeBlock: CooldownBlock | undefined;

/** A transcript row that mimics a user message with a live countdown below. */
class CooldownBlock extends Container {
	private dismissed = false;
	private readonly status: Text;
	private readonly timer: ReturnType<typeof setInterval>;

	constructor(
		private readonly tui: TUI | undefined,
		private readonly theme: Theme,
		private readonly deadlineAt: number,
		message: string,
	) {
		super();

		// Mimic a regular user message: background box + wrapped text.
		const messageBox = new Box(1, 1, (s: string) => theme.bg("userMessageBg", s));
		messageBox.addChild(new Text(theme.fg("userMessageText", message), 0, 0));
		this.addChild(messageBox);

		this.status = new Text("", 1, 0);
		this.addChild(this.status);

		this.timer = setInterval(() => this.tick(), TICK_MS);
		this.tick();
	}

	private statusText(remainingMs: number): string {
		const seconds = Math.ceil(remainingMs / 1000);
		return (
			this.theme.fg("muted", "sending in ") +
			this.theme.fg("accent", `${seconds}s`) +
			this.theme.fg("muted", "  •  ") +
			this.theme.fg("warning", "Enter") +
			this.theme.fg("muted", " to send now, ") +
			this.theme.fg("warning", "Esc") +
			this.theme.fg("muted", " to cancel")
		);
	}

	private tick(): void {
		const remaining = this.deadlineAt - Date.now();
		if (remaining <= 0) {
			this.dismiss();
			return;
		}
		this.status.setText(this.statusText(remaining));
		this.tui?.requestRender();
	}

	/** Collapse to zero height in the transcript and stop ticking. */
	dismiss(): void {
		if (this.dismissed) return;
		this.dismissed = true;
		clearInterval(this.timer);
		this.clear();
		this.tui?.requestRender();
	}
}

export default function (pi: ExtensionAPI) {
	// Capture the TUI handle once. registerEntryRenderer() callbacks get no TUI,
	// so a zero-height widget is the side channel that hands it to us.
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setWidget("send-cooldown-tui", (tui) => {
			tuiRef = tui;
			return { render: (): string[] => [], invalidate() {} };
		});
	});

	pi.registerEntryRenderer<{ text: string; deadlineAt: number }>(
		"send-cooldown",
		(entry, _options, theme) => {
			const { text, deadlineAt } = entry.data ?? { text: "", deadlineAt: 0 };
			if (Date.now() >= deadlineAt) return undefined; // stale entry (reload) → invisible
			const block = new CooldownBlock(tuiRef, theme, deadlineAt, text);
			activeBlock = block;
			return block;
		},
	);

	pi.on("input", async (event, ctx) => {
		// Terminal-only, user-typed, idle free-text only.
		if (ctx.mode !== "tui") return { action: "continue" };
		if (event.source !== "interactive") return { action: "continue" };
		if (event.streamingBehavior) return { action: "continue" }; // steer/followUp must be instant
		if (!shouldDelay(event.text)) return { action: "continue" };

		// Show the pending message in the transcript body (TUI-only, not sent to
		// the LLM; it collapses once the deadline passes).
		pi.appendEntry<{ text: string; deadlineAt: number }>("send-cooldown", {
			text: event.text,
			deadlineAt: Date.now() + COOLDOWN_MS,
		});

		const result = await new Promise<"send" | "cancel">((resolve) => {
			let finished = false;

			// Catch the follow-up Enter (send now) or Esc/Ctrl+C (cancel). The
			// block is not a focused component, so raw terminal input is the way
			// to read keys while the editor is idle.
			const unsubscribe = ctx.ui.onTerminalInput((data) => {
				if (matchesKey(data, "enter")) {
					finish("send");
				} else if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
					finish("cancel");
				}
				// Swallow every key while the cooldown is active, exactly like the
				// focused overlay this replaced did.
				return { consume: true };
			});

			const autoSend = setTimeout(() => finish("send"), COOLDOWN_MS);

			function finish(r: "send" | "cancel"): void {
				if (finished) return;
				finished = true;
				unsubscribe();
				clearTimeout(autoSend);
				resolve(r);
			}
		});

		// Collapse the preview block now that the decision has been made.
		activeBlock?.dismiss();
		activeBlock = undefined;

		if (result === "cancel") {
			ctx.ui.setEditorText(event.text); // put it back for editing
			tuiRef?.requestRender(); // repaint so the restored text shows immediately
			return { action: "handled" }; // never sent, never recorded
		}
		return { action: "continue" };
	});
}
