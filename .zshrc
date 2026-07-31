PROMPT_EOL_MARK=''

source "$HOME/.config/shell/env_vars.sh"

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Zsh-specific modules
[[ -d "$HOME/.zfunc" ]] && fpath+=("$HOME/.zfunc")
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

# NVM (Node Version Manager) is expensive to initialize, especially when HOME
# is on a network filesystem. Load it only when a Node-related command is used.
export NVM_DIR="$HOME/.nvm"
if [[ -n "${NVM_BIN:-}" ]]; then
  path=("${(@)path:#$NVM_BIN}")
  unset NVM_BIN NVM_INC
fi

_load_nvm() {
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    print -u2 "NVM is not installed under $NVM_DIR"
    return 127
  fi

  unfunction nvm node npm npx corepack 2>/dev/null
  source "$NVM_DIR/nvm.sh" --no-use
  nvm use default --silent >/dev/null || return
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

nvm() { _load_nvm || return; nvm "$@" }
node() { _load_nvm || return; command node "$@" }
npm() { _load_nvm || return; command npm "$@" }
npx() { _load_nvm || return; command npx "$@" }
corepack() { _load_nvm || return; command corepack "$@" }

eval "$(zoxide init --cmd cd zsh)"

# Don't memorize $HOME's direct children (~/Downloads, ~/.config, ...), but keep
# memorizing anything deeper (~/projects/foo). _ZO_EXCLUDE_DIRS can't express
# this: its globs are depth-blind ('*' crosses '/'), so "$HOME/*" would exclude
# the whole tree. Filter in zoxide's own chpwd hook instead.
function __zoxide_hook() {
  local dir
  dir="$(__zoxide_pwd)" || return 0
  [[ "${dir%/*}" == "$HOME" ]] && return 0
  command zoxide add -- "$dir"
}

# opencode
if [ -d "$HOME/.opencode/bin" ]; then 
  export PATH=$HOME/.opencode/bin:$PATH
fi

# bun completions
[ -s "/Users/artem/.bun/_bun" ] && source "/Users/artem/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

zstyle ':completion:*' menu select
