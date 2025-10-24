if [ -d "$HOME/miniforge3" ]; then
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$("$HOME/miniforge3/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
            . "$HOME/miniforge3/etc/profile.d/conda.sh"
        else
            export PATH="$HOME/miniforge3/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<

    export MAMBA_EXE="$HOME/miniforge3/bin/mamba";
    export MAMBA_ROOT_PREFIX="$HOME/miniforge3";
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__mamba_setup"
    else
        # alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
        if [ -f "$HOME/miniforge3/etc/profile.d/mamba.sh" ]; then
            . "$HOME/miniforge3/etc/profile.d/mamba.sh"
        fi
    fi
    unset __mamba_setup
fi

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
