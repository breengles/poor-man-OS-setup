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

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

eval "$(zoxide init --cmd cd zsh)"

# opencode
export PATH=$HOME/.opencode/bin:$PATH
