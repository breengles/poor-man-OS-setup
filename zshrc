# export PATH=$HOME/bin:/usr/local/bin:$HOME/.local/bin:$PATH

## nvidia cuda if u need it
# export PATH=/usr/local/cuda-11.2/bin${PATH:+:${PATH}}
# export PATH=/usr/local/cuda/bin/:$PATH

## intel's OneAPI
# source /opt/intel/oneapi/setvars.sh >/dev/null

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

## just remind me to update when it's time
zstyle ':omz:update' mode reminder

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
)

source $ZSH/oh-my-zsh.sh

## aliases and functions
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias c="clear"
alias ll="ls -ltr"

function rcp() {
  rsync -azhP "$@"
}

