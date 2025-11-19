# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Switch to zsh
if command -v zsh &> /dev/null; then
    export SHELL=$(command -v zsh)
    exec zsh
fi

export PATH=$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH

# History Configuration (matching zsh settings)
HISTSIZE=5000
HISTFILESIZE=5000
HISTFILE=~/.bash_history

# Don't put duplicate lines or lines starting with space in history
HISTCONTROL=ignorespace:ignoredups:erasedups

# Append to the history file, don't overwrite it
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Update history after each command (similar to zsh sharehistory)
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Keybindings - History search with arrow keys
bind '"\e[A": history-search-backward'  # Up arrow
bind '"\e[B": history-search-forward'   # Down arrow

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Starship prompt configuration
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Shell integrations
source "$HOME/.config/shell/functions.sh"
source "$HOME/.config/shell/aliases.sh"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/google-cloud-sdk/path.bash.inc"; fi
# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/google-cloud-sdk/completion.bash.inc"; fi

if [ -f $HOME/.fzf.bash ]; then source $HOME/.fzf.bash; fi

. "$HOME/.cargo/env"

if [ -f "$HOME/.completion.uv.bash" ]; then source "$HOME/.completion.uv.bash"; fi

# Initialize Starship prompt
eval "$(starship init bash)"
