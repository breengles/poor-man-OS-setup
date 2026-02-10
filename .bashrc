# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac

# Switch to zsh
zsh_path=$(command -v zsh)
if [ -x "$zsh_path" ] && [[ "$SHELL" != "$zsh_path" ]] && [[ $(hostname) != "login-"* ]]; then
  export SHELL="$zsh_path"
  exec zsh
else
  source "$HOME/.config/shell/env_vars.sh"

  # History Configuration (matching zsh settings)
  HISTSIZE=20000
  HISTFILESIZE=$HISTSIZE
  HISTFILE=~/.bash_history
  HISTCONTROL=ignorespace:ignoredups:erasedups # Don't put duplicate lines or lines starting with space in history
  shopt -s histappend # Append to the history file, don't overwrite it
  shopt -s cmdhist # Save multi-line commands as one command
  PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}" # Update history after each command (similar to zsh sharehistory)
  # Keybindings - History search with arrow keys
  bind '"\e[A": history-search-backward'  # Up arrow
  bind '"\e[B": history-search-forward'   # Down arrow
  shopt -s checkwinsize # check the window size after each command and, if necessary, update the values of LINES and COLUMNS.

  # If set, the pattern "**" used in a pathname expansion context will
  # match all files and zero or more directories and subdirectories.
  #shopt -s globstar

  # make less more friendly for non-text input files, see lesspipe(1)
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

  # enable programmable completion features (you don't need to enable
  # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
  # sources /etc/bash.bashrc).
  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      source /etc/bash_completion
    fi
  fi

  # The next line updates PATH for the Google Cloud SDK.
  if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/google-cloud-sdk/path.bash.inc"; fi
  # The next line enables shell command completion for gcloud.
  if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/google-cloud-sdk/completion.bash.inc"; fi

  if [ -f $HOME/.fzf.bash ]; then source $HOME/.fzf.bash; fi

  source "$HOME/.cargo/env"

  if [ -f "$HOME/.completion.uv.bash" ]; then source "$HOME/.completion.uv.bash"; fi

  # Initialize Starship prompt
  eval "$(starship init bash)"

  source "$HOME/.config/shell/functions.sh"
  source "$HOME/.config/shell/aliases.sh"
fi
