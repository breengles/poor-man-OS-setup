#!/usr/bin/env bash

alias c="clear"
alias zshconfig="vim ~/.zshrc"
alias watch="watch -c"

alias initifort="source /opt/intel/oneapi/setvars.sh >/dev/null"

# rsync
alias rsync-copy="rsync -ah --info=progress2"
alias rsync-move="rsync -ah --remove-source-files --info=progress2"
alias rsync-update="rsync -auh --info=progress2"
alias rsync-synchronize="rsync -auh --delete --info=progress2"

alias rcopy="rsync-copy"
alias rmove="rsync-move"
alias rupd="rsync-update"
alias rsync-sync="rsync-synchronize"

if [ -x "$(command -v nvim)" ]; then
  alias vim=nvim
  export EDITOR=nvim
fi

if [ -x "$(command -v zellij)" ]; then
  alias zl=zellij
fi

if [ -x "$(command -v eza)" ] && [ -z "$AGENT" ] && [ -z "$CLAUDECODE" ]; then
  alias ls="eza --color=always --group-directories-first"
  alias l="eza --color=always --long --group-directories-first"
  alias ll="eza --color=always -abghHlS --group-directories-first"
else
  alias l="ls -lh"
  alias ll="ls -lAh"
fi


if [ -x "$(command -v bat)" ] && [ -z "$AGENT" ] && [ -z "$CLAUDECODE" ]; then
  alias cat=bat
fi

if [ -x "$(command -v sbatch)" ]; then
  alias s=sbatch
fi

if [ -x "$(command -v fd)" ]; then
  alias fd="fd --no-ignore"
fi

if [ -x "$(command -v pcpctl)" ]; then
  alias pcp="pcpctl"
fi


alias deact=deactivate
