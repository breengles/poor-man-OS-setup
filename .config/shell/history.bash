HISTSIZE=20000
HISTFILESIZE=$HISTSIZE
HISTFILE="$HOME/.bash_history"
HISTCONTROL=ignorespace:ignoredups:erasedups
shopt -s histappend
shopt -s cmdhist
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
