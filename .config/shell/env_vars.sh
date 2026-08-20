export WORDCHARS=''
export PATH="$HOME/go/bin:$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH"

export OLLAMA_API_BASE="http://127.0.0.1:11434"

# Ollama serves 4096 tokens of context by default and silently truncates past
# it. pi declares each model's window in ~/.pi/agent/models.json, and
# `pi_sync_models` caps that declaration at this value, so the two agree.
# 256K is the ceiling, not a promise: a model whose native window is smaller
# still gets its own window, because `pi_sync_models` takes the minimum of
# the two. The KV cache grows with whatever window actually ends up in use.
export OLLAMA_CONTEXT_LENGTH=262144

# Serving settings, tuned for one interactive agent on a single machine rather
# than for throughput. A 256K window makes the KV cache the memory bottleneck,
# so flash attention plus an 8-bit cache halve it at negligible quality cost;
# q8_0 needs flash attention to take effect at all. One request at a time and
# one resident model keep a single agent's cache from competing with a second
# copy of itself. 30m of keep-alive avoids reloading tens of GB between turns.
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_KV_CACHE_TYPE=q8_0
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE=30m

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

