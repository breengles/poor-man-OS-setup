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
source "$HOME/.config/shell/node.sh"
source "$HOME/.config/shell/integrations.sh"  # starship, fzf, cargo, gcloud, completions, tokens

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
