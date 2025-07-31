#!/usr/bin/env bash

alias c="clear"
alias zshconfig="vim ~/.zshrc"

alias initifort="source /opt/intel/oneapi/setvars.sh >/dev/null"

# rsync
alias rsync-copy="rsync -ah --info=progress2"
alias rsync-move="rsync -ah --remove-source-files --info=progress2"
alias rsync-update="rsync -auh --info=progress2"
alias rsync-synchronize="rsync -auh --delete --info=progress2"

alias rcopy="rsync-copy"
alias rmove="rsync-move"
alias rupd="rsync-update"

if [ -x "$(command -v nvim)" ]; then
  alias vim=nvim
  export EDITOR=nvim
fi

if [ -x "$(command -v zellij)" ]; then
  alias zl=zellij
  alias jobs="zl attach --create jobs"
fi

if [ -x "$(command -v eza)" ]; then
  alias ls="eza --color=always"
  alias l="eza --color=always --long"
  alias ll="eza --color=always -abghHlS"
fi

if [ -x "$(command -v ollama)" ]; then
  alias ol=ollama
fi

if [ -x "$(command -v bat)" ]; then
  alias cat=bat
fi

if [ -x "$(command -v sbatch)" ]; then
  alias s=sbatch
fi

if [ -x "$(command -v cursor)" ]; then
  alias code=cursor
fi

alias deact=deactivate

# slurm
alias spython='srun --nodes=1 --ntasks=1 --cpus-per-task=16 --mem-per-gpu=64G --gres=gpu:1 --partition=scalar6000q --time=30-00:00:00 python -u'
