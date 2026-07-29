export WORDCHARS=''
export PATH="$HOME/go/bin:$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH"

export OLLAMA_API_BASE="http://127.0.0.1:11434"

# Skip auto-sync of .venv on `uv run`. Sync explicitly with `uv sync` instead.
export UV_NO_SYNC=1

export GRADIO_TEMP_DIR="$HOME/gradio_tmp"
[ ! -d "$GRADIO_TEMP_DIR" ] && mkdir -p "$GRADIO_TEMP_DIR"

export STARSHIP_CONFIG="$HOME/.config/starship.toml"

export PCPCTL_FEATURE_FLAGS=jobs

# zoxide: keep build/env/scratch dirs out of the database. ':'-separated globs;
# zoxide's '*' crosses '/' and matches leading dots, so these match at any depth.
# This replaces zoxide's default value (just "$HOME"), hence the leading "$HOME".
# Depth-limited rules can't be expressed here -- see the hook in .zshrc.
export _ZO_EXCLUDE_DIRS="$HOME:/tmp/*:/private/tmp/*:/var/folders/*:*/node_modules*:*/.git:*/.git/*:*/.venv*:*/site-packages*:*/__pycache__*:*/.mypy_cache*:*/.pytest_cache*:*/target/debug*"

