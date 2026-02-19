PROMPT_EOL_MARK=''

source "$HOME/.config/shell/env_vars.sh"

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Zsh-specific modules
source "$HOME/.config/shell/zinit.zsh"
source "$HOME/.config/shell/cluster.zsh"
source "$HOME/.config/shell/history.zsh"
source "$HOME/.config/shell/keybindings.zsh"
source "$HOME/.config/shell/completions.zsh"

# Shared modules (shell-agnostic)
source "$HOME/.config/shell/functions.sh"
source "$HOME/.config/shell/aliases.sh"
source "$HOME/.config/shell/integrations.sh"  # starship, fzf, cargo, gcloud, completions, tokens

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
