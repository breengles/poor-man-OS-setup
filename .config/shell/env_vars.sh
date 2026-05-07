export WORDCHARS=''
export PATH="$HOME/go/bin:$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH"

export OLLAMA_API_BASE="http://127.0.0.1:11434"

# Skip auto-sync of .venv on `uv run`. Sync explicitly with `uv sync` instead.
export UV_NO_SYNC=1

export GRADIO_TEMP_DIR="$HOME/gradio_tmp"
[ ! -d "$GRADIO_TEMP_DIR" ] && mkdir -p "$GRADIO_TEMP_DIR"

export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Export current macOS theme for SSH forwarding to remote machines.
# Used by TUI apps (Claude Code, etc.) to match system appearance.
if command -v defaults &>/dev/null; then
  if defaults read -g AppleInterfaceStyle &>/dev/null 2>&1; then
    export MACOS_SYSTEM_THEME="dark"
  else
    export MACOS_SYSTEM_THEME="light"
  fi
fi
