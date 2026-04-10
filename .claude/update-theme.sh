#!/usr/bin/env bash
# Sync Claude Code theme with system appearance.
# Usage: call before launching claude (the shell wrapper does this automatically).
#
# Detection priority (handled by detect-theme.py):
#   1. OSC 11 terminal query (works locally, over SSH, and in tmux 3.3+)
#   2. macOS appearance detection (local only)
#   3. $MACOS_SYSTEM_THEME env var (fallback for old tmux / no TTY)
#   4. No change

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_JSON="$HOME/.claude.json"

theme=$(python3 "$SCRIPT_DIR/detect-theme.py" 2>/dev/null) || true
[[ -z "$theme" ]] && exit 0

if [[ ! -f "$CLAUDE_JSON" ]]; then
    echo "{\"theme\": \"$theme\"}" > "$CLAUDE_JSON"
    exit 0
fi

# Write only if the value is missing or different
python3 -c "
import json, pathlib, sys
p = pathlib.Path('$CLAUDE_JSON')
d = json.loads(p.read_text())
if d.get('theme') == '$theme':
    sys.exit(0)
d['theme'] = '$theme'
p.write_text(json.dumps(d, indent=2) + '\n')
"
