PROMPT_EOL_MARK=''

source "$HOME/.config/shell/env_vars.sh"

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Shell integrations
files=(
  "$HOME/.config/shell/zinit.zsh"
  "$HOME/.cargo/env"
  "$HOME/.fzf.zsh"
  "$HOME/.config/shell/cluster.zsh"
  "$HOME/.config/shell/functions.sh"
  "$HOME/.config/shell/aliases.sh"
  "$HOME/.config/shell/history.zsh"
  "$HOME/.config/shell/keybindings.zsh"
  "$HOME/.config/shell/completions.zsh"
)
for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    source "$file"
  else
    echo "File $file not found" >&2
  fi
done

# Initialize Starship prompt (must be after zinit)
[ -x "$(command -v starship)" ] && eval "$(starship init zsh)"

# add tokens
if [ -f "$HOME/.env-global.sh" ]; then source "$HOME/.env-global.sh"; fi

# add completions
if [ -f "$HOME/.completion.adkb.sh" ]; then source "$HOME/.completion.adkb.sh"; fi
if [ -f "$HOME/.completion.uv.sh" ]; then source "$HOME/.completion.uv.sh"; fi
if [ -f "$HOME/.completion.glab.zsh" ]; then source "$HOME/.completion.glab.zsh"; fi
if [ -f "$HOME/.completion.pueue.zsh" ]; then source "$HOME/.completion.pueue.zsh"; fi
if [ -f "$HOME/.completion.pcpctl.zsh" ]; then source "$HOME/.completion.pcpctl.zsh"; fi
if [ -f "$HOME/.completion.opencode.sh" ]; then source "$HOME/.completion.opencode.sh"; fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then source "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then source "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# Lazy-load NVM to avoid 50-200ms startup penalty
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  function _load_nvm {
    unfunction nvm node npm npx 2>/dev/null
    \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  }
  function nvm { _load_nvm; nvm "$@" }
  function node { _load_nvm; node "$@" }
  function npm { _load_nvm; npm "$@" }
  function npx { _load_nvm; npx "$@" }
fi

eval "$(zoxide init --cmd cd zsh)"
