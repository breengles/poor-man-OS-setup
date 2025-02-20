#!/usr/bin/env bash

function calcimages {
  find "$1" -type f \( -name \*.jpg -o -name \*.jpeg -o -name \*.png \) | wc -l
}

function update {
  echo -e "\n========== updating zinit ==========\n"
  zinit self-update
  zinit update --all --parallel

  echo -e "\n========== updating os packages ==========\n"
  if [ -x "$(command -v brew)" ]; then
    brew update && brew upgrade
  fi

  if [ -x "$(command -v apt)" ]; then
    sudo apt update && sudo apt upgrade
  fi

  echo -e "\n========== updating mamba ==========\n"
  mamba update --all -y && mamba clean --all -y

  echo -e "\n========== updating cargo ==========\n"
  cargo install-update --all --jobs 8
}

function mambac {
  local python_version="3.11"
  local env_name

  if [ $# -eq 1 ]; then
    env_name=$1
  else
    python_version=$1
    env_name=$2
  fi

  if conda env list | grep -q "^$env_name\b"; then
    echo "Environment '$env_name' already exists."
  else
    mamba create -y -n "$env_name" python="$python_version"
  fi

  mamba activate "$env_name"
}

function echo_project_info {
  echo "===== SYS INFO ====="
  echo "Your job ($SLURM_JOB_NAME) is running on $(hostname)"

  nvidia-smi
  echo "GPUs: $CUDA_VISIBLE_DEVICES"
  echo "Torch CUDA is available: $(python -c 'import torch; print(torch.cuda.is_available())')"

  echo "Commit hash: $(git rev-parse HEAD)"

  echo "python: $(python -V) @ $(which python)"
  echo "pip: $(pip -V) @ $(which pip)"
  pip freeze
  echo "===================="
}

function activate {
  conda deactivate
  source ./.venv/bin/activate
}

# some stuff for remote cluster
function s {
  sbatch "$@"
}

function q {
  sinfo
  echo ""
  squeue --user="$(whoami)" --format="%.11i %.11P %45j %.8T %.12M %18N"
  echo -e "\nTotal number of jobs: $(squeue --user="$(whoami)" -h | wc -l)"
}

function qq {
  watch -n 1 "squeue --user=$(whoami) --format='%.11i %.11P %45j %.1T %.12M %18N'; echo -e '\nTotal number of jobs: '; squeue --user=$(whoami)  -h | wc -l"
}

function gpu {
  ssh "lambda-scalar0$1" -t "$(which nvitop)"
}
