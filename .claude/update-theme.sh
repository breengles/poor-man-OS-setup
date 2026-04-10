#!/usr/bin/env bash
# Sync Claude Code theme with system appearance.
# Usage: call before launching claude (the shell wrapper does this automatically).
#
# Detection priority:
#   1. OSC 11 terminal query (works locally, over SSH, and in tmux 3.3+)
#   2. macOS appearance detection (local only)
#   3. $MACOS_SYSTEM_THEME env var (fallback for old tmux / no TTY)
#   4. No change

set -euo pipefail

CLAUDE_JSON="$HOME/.claude.json"

detect_theme_osc11() {
    # Query terminal background color via OSC 11. Requires a real TTY.
    [[ -t 0 && -t 1 ]] || return 1

    python3 -c "
import sys, os, select, termios, tty, re

fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)
try:
    tty.setraw(fd)
    os.write(sys.stdout.fileno(), b'\x1b]11;?\x1b\\\\')
    # Read response with 0.5s timeout
    resp = b''
    while select.select([sys.stdin], [], [], 0.5)[0]:
        resp += os.read(fd, 256)
        if b'\x1b\\\\' in resp or b'\x07' in resp:
            break
finally:
    termios.tcsetattr(fd, termios.TCSADRAIN, old)

m = re.search(rb'rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)', resp)
if not m:
    sys.exit(1)

# Normalize to 0-1 range (values can be 2 or 4 hex digits)
vals = []
for g in m.groups():
    v = int(g, 16)
    vals.append(v / 0xFF if len(g) <= 2 else v / 0xFFFF)

# Perceived luminance (ITU-R BT.601)
lum = 0.299 * vals[0] + 0.587 * vals[1] + 0.114 * vals[2]
print('light' if lum > 0.5 else 'dark')
" 2>/dev/null
}

detect_theme() {
    local theme

    # 1. OSC 11 — works locally, over SSH, and in tmux 3.3+
    theme=$(detect_theme_osc11) && [[ -n "$theme" ]] && echo "$theme" && return

    # 2. macOS detection
    if command -v defaults &>/dev/null; then
        if defaults read -g AppleInterfaceStyle &>/dev/null 2>&1; then
            echo "dark"
        else
            echo "light"
        fi
        return
    fi

    # 3. Env var fallback (e.g. forwarded via SSH)
    if [[ -n "${MACOS_SYSTEM_THEME:-}" ]]; then
        echo "$MACOS_SYSTEM_THEME"
        return
    fi

    # 4. Unknown — don't change
    echo ""
}

apply_theme() {
    local theme="$1"
    [[ -z "$theme" ]] && return 0

    if [[ ! -f "$CLAUDE_JSON" ]]; then
        echo "{\"theme\": \"$theme\"}" > "$CLAUDE_JSON"
        return
    fi

    # Read current theme — use __UNSET__ sentinel so missing key != "dark"
    local current
    current=$(python3 -c "import json; print(json.load(open('$CLAUDE_JSON')).get('theme','__UNSET__'))" 2>/dev/null || echo "__UNSET__")

    if [[ "$current" == "$theme" ]]; then
        return 0
    fi

    # Update theme in-place using python3 (available on macOS and most Linux)
    python3 -c "
import json, pathlib
p = pathlib.Path('$CLAUDE_JSON')
d = json.loads(p.read_text())
d['theme'] = '$theme'
p.write_text(json.dumps(d, indent=2) + '\n')
"
}

theme=$(detect_theme)
apply_theme "$theme"
