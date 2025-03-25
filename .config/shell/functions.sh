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

  if [[ $(hostname) != "lambda-loginnode"* ]]; then
    if [ -x "$(command -v apt)" ]; then
      sudo apt update && sudo apt upgrade
    fi
  fi

  echo -e "\n========== updating mamba ==========\n"
  mamba update --all -y && mamba clean --all -y

  echo -e "\n========== updating cargo ==========\n"
  cargo install-update --all --jobs 8
}

function mambac {
  local python_version
  local env_name

  python_version="3.11"
  env_name="$(basename "$(pwd)")"

  if [ $# -eq 1 ]; then
    python_version="$1"
    env_name="$(basename "$(pwd)")"
  elif [ $# -eq 2 ]; then
    python_version="$1"
    env_name="$2"
  fi

  echo "Creating environment $env_name with python $python_version ..."
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
  local venv_path=".venv"
  
  # Override venv_path if provided as an argument
  if [ $# -eq 1 ]; then
    venv_path="$1"
  fi
  
  if [ -d "$venv_path" ]; then
    conda deactivate
    source "$venv_path/bin/activate"
  else
    echo "Virtual environment '$venv_path' does not exist."
  fi
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
