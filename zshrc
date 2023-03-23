# export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH

### nvidia cuda if u need it ###
# export PATH=/usr/local/cuda-11.2/bin${PATH:+:${PATH}}
# export PATH=/usr/local/cuda/bin/:$PATH

source $HOME/.aliases

# From intel's OneAPI
# source /opt/intel/oneapi/setvars.sh >/dev/null


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
  command-not-found
  zsh-syntax-highlighting
  zsh-autosuggestions
  conda-zsh-completion
)

source $ZSH/oh-my-zsh.sh

alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
