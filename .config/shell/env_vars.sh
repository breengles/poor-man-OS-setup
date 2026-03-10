export WORDCHARS=''
export PATH="$HOME/go/bin:$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH"

export OLLAMA_API_BASE="http://127.0.0.1:11434"

export GRADIO_TEMP_DIR="$HOME/gradio_tmp"
[ ! -d "$GRADIO_TEMP_DIR" ] && mkdir -p "$GRADIO_TEMP_DIR"

export STARSHIP_CONFIG="$HOME/.config/starship.toml"
