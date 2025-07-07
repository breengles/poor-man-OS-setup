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

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p)
        shift
        if [[ $# -gt 0 ]]; then
          python_version="$1"
          shift
        else
          echo "Error: Python version argument missing after -p"
          return 1
        fi
        ;;
      -n)
        shift
        if [[ $# -gt 0 ]]; then
          env_name="$1"
          shift
        else
          echo "Error: Environment name argument missing after -n"
          return 1
        fi
        ;;
      *)
        echo "Usage: mambac [-p python_version] [-n env_name]"
        return 1
        ;;
    esac
  done

  echo "Creating environment \`$env_name\` with python \`$python_version\` ..."
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
  echo "Torch CUDA is available: $(python3 -c 'import torch; print(torch.cuda.is_available())')"

  echo "Commit hash: $(git rev-parse HEAD)"

  echo "python: $(python3 -V) @ $(which python3)"
  echo "pip: $(pip3 -V) @ $(which pip3)"
  pip freeze
  echo "===================="
}

function act {
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

function gpu_usage {
  squeue -t RUNNING -h -o "%u %b %P" | awk '{
      user=$1; gres=$2; partition=$3;
      user_jobs[user]++;
      user_partition_jobs[user,partition]++;
      
      # Track all unique partitions
      all_partitions[partition] = 1;
      
      gpu_count=0;
      if (gres ~ /gpu/) {
          if (match(gres, /gpu:([0-9]+)/, arr)) {
              gpu_count = arr[1];
          } else if (gres ~ /gpu/) {
              gpu_count = 1;
          }
          user_gpus[user] += gpu_count;
          user_partition_gpus[user,partition] += gpu_count;
      }
  } END {
      # Create sorted array of partitions
      n_partitions = 0;
      for (p in all_partitions) {
          partition_list[++n_partitions] = p;
      }
      # Sort partitions
      for (i = 1; i <= n_partitions; i++) {
          for (j = i + 1; j <= n_partitions; j++) {
              if (partition_list[i] > partition_list[j]) {
                  temp = partition_list[i];
                  partition_list[i] = partition_list[j];
                  partition_list[j] = temp;
              }
          }
      }
      
      # Print header
      header = sprintf("%-20s %4s %4s", "User", "Jobs", "GPUs");
      separator = sprintf("%-20s %4s %4s", "----", "----", "----");
      for (i = 1; i <= n_partitions; i++) {
          header = header sprintf(" %15s", partition_list[i]);
          separator = separator sprintf(" %15s", "---------------");
      }
      print header;
      print separator;
      
      # Store user data for sorting
      n_users = 0;
      for (user in user_jobs) {
          user_list[++n_users] = user;
      }
      
      # Sort users by GPU count (descending)
      for (i = 1; i <= n_users; i++) {
          for (j = i + 1; j <= n_users; j++) {
              if (user_gpus[user_list[i]] < user_gpus[user_list[j]]) {
                  temp = user_list[i];
                  user_list[i] = user_list[j];
                  user_list[j] = temp;
              }
          }
      }
      
      # Print sorted user data
      for (i = 1; i <= n_users; i++) {
          user = user_list[i];
          line = sprintf("%-20s %4d %4d", user, user_jobs[user], user_gpus[user]+0);
          for (j = 1; j <= n_partitions; j++) {
              p = partition_list[j];
              p_jobs = user_partition_jobs[user,p] + 0;
              p_gpus = user_partition_gpus[user,p] + 0;
              if (p_jobs > 0 || p_gpus > 0) {
                  line = line sprintf(" %15s", p_jobs " jobs, " p_gpus " gpus");
              } else {
                  line = line sprintf(" %15s", "");
              }
          }
          print line;
      }
  }'
}