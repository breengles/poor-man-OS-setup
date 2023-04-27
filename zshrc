# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH

## nvidia cuda if u need it
# export PATH=/usr/local/cuda-11.2/bin${PATH:+:${PATH}}
# export PATH=/usr/local/cuda/bin/:$PATH

## intel's OneAPI
# source /opt/intel/oneapi/setvars.sh >/dev/null

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

## just remind me to update when it's time
# zstyle ':omz:update' mode reminder

export UPDATE_ZSH_DAYS=13
ZSH_CUSTOM_AUTOUPDATE_QUIET=true

## Which plugins would you like to load?
## Standard plugins can be found in $ZSH/plugins/
## Custom plugins may be added to $ZSH_CUSTOM/plugins/
## Example format: plugins=(rails git textmate ruby lighthouse)
## Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  pip
  command-not-found
  zsh-syntax-highlighting
  zsh-autosuggestions
  conda-zsh-completion
  autoupdate
)

source $ZSH/oh-my-zsh.sh

alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias c="clear"

function rcp() {
  rsync -azhP "$@"
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/artem.kotov/mambaforge/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/artem.kotov/mambaforge/etc/profile.d/conda.sh" ]; then
        . "/Users/artem.kotov/mambaforge/etc/profile.d/conda.sh"
    else
        export PATH="/Users/artem.kotov/mambaforge/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "/Users/artem.kotov/mambaforge/etc/profile.d/mamba.sh" ]; then
    . "/Users/artem.kotov/mambaforge/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
