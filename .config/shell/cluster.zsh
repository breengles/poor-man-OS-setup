if [[ "$HOST" == lambda-loginnode* ]]; then
  # Bash already sourced /etc/profile before it exec'd Zsh. Initialize only
  # the module command here because Bash functions are not inherited by Zsh.
  if (( ! $+functions[module] )); then
    if [[ -n "${MODULESHOME:-}" && -r "$MODULESHOME/init/zsh" ]]; then
      source "$MODULESHOME/init/zsh"
    elif [[ -r /etc/profile.d/modules.sh ]]; then
      source /etc/profile.d/modules.sh
    fi
  fi

  if (( $+functions[module] )); then
    case ":${LOADEDMODULES:-}:" in
      *:slurm/*:*) ;;
      *) module load slurm ;;
    esac

    case ":${LOADEDMODULES:-}:" in
      *:cuda12.4/toolkit/*:*) ;;
      *) module load cuda12.4/toolkit/12.4.1 ;;
    esac
  else
    print -u2 "Unable to initialize the environment modules command"
  fi
fi
