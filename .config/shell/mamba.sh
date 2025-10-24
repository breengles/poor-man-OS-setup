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
