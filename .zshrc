export WORDCHARS='*?_[]~&!$(){}<>'
export PATH=$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH

export OLLAMA_API_BASE="http://127.0.0.1:11434"

export GRADIO_TEMP_DIR="$HOME/gradio_tmp"
mkdir -p "$GRADIO_TEMP_DIR"

# Starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Shell integrations
files=(
  "$HOME/.config/shell/zinit.zsh"
  "$HOME/.fzf.zsh"
  "$HOME/.config/shell/cluster.zsh"
  "$HOME/.config/shell/functions.sh"
  "$HOME/.config/shell/aliases.sh"
  "$HOME/.config/shell/history.zsh"
  "$HOME/.config/shell/keybindings.zsh"
  "$HOME/.config/shell/completions.zsh"
)
for file in "${files[@]}"; do
    [ -f "$file" ] && source "$file" || echo "File $file not found"
done

# Initialize Starship prompt (must be after zinit)
eval "$(starship init zsh)"

# add tokens
if [ -f "$HOME/.env-global.sh" ]; then source "$HOME/.env-global.sh"; fi

# add completions
if [ -f "$HOME/.completion.adkb.sh" ]; then source "$HOME/.completion.adkb.sh"; fi
if [ -f "$HOME/.completion.uv.sh" ]; then source "$HOME/.completion.uv.sh"; fi
if [ -f "$HOME/.completion.pueue.zsh" ]; then source "$HOME/.completion.pueue.zsh"; fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then source "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then source "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(zoxide init --cmd cd zsh)"
