# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$HOME.local/bin:$PATH

# if using pyenv
export PYENV_ROOT="$HOME/.pyenv"

command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

### nvidia cuda if u need it ###
# export PATH=/usr/local/cuda-11.2/bin${PATH:+:${PATH}}
# export PATH=/usr/local/cuda/bin/:$PATH

source ~/.aliases
source ~/antigen.zsh

# Oh-my-zsh
antigen use oh-my-zsh

# Bundles
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle poetry

# Theme
antigen theme robbyrussell

# We are done
antigen apply

# From intel's OneAPI
. /opt/intel/oneapi/setvars.sh >/dev/null


# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/breengles/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/breengles/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/breengles/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/breengles/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
