export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH

### nvidia cuda if u need it ###
# export PATH=/usr/local/cuda-11.2/bin${PATH:+:${PATH}}
# export PATH=/usr/local/cuda/bin/:$PATH

source $HOME/.aliases

# From intel's OneAPI
source /opt/intel/oneapi/setvars.sh >/dev/null


# oh my zsh
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  pip
  lein
  command-not-found
  zsh-syntax-highlighting
  zsh-autosuggestions
  conda-zsh-completion
)

source $ZSH/oh-my-zsh.sh

alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/breengles/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/breengles/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/breengles/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/breengles/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
