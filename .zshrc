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
source "$HOME/.config/shell/claude-tmux.zsh"
source "$HOME/.config/shell/tmux.zsh"

# Shared modules (shell-agnostic)
source "$HOME/.config/shell/functions.sh"
source "$HOME/.config/shell/aliases.sh"
source "$HOME/.config/shell/integrations.sh"  # starship, fzf, cargo, gcloud, completions, tokens

# NVM (Node Version Manager) — force-activate default so inherited NVM_BIN
# from a parent process doesn't pin us to a stale node version.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" && nvm use default --silent >/dev/null
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

eval "$(zoxide init --cmd cd zsh)"

# opencode
if [ -d "$HOME/.opencode/bin" ]; then 
  export PATH=$HOME/.opencode/bin:$PATH
fi

# bun completions
[ -s "/Users/artem/.bun/_bun" ] && source "/Users/artem/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
