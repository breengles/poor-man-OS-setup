export PATH=$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH
export OLLAMA_API_BASE="http://127.0.0.1:11434"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Shell integrations
files=(
    "$HOME/.config/shell/zinit.zsh"
    "$HOME/.config/shell/history.zsh"
    "$HOME/.config/shell/keybindings.zsh"
    "$HOME/.config/shell/completions.zsh"
    "$HOME/.p10k.zsh"
    "$HOME/.fzf.zsh"
    "$HOME/.adkb.sh"
    "$HOME/.config/shell/emulate_bash_stuff.zsh"
    "$HOME/.config/shell/aliases.sh"
    "$HOME/.config/shell/functions.sh"
)
for file in "${files[@]}"; do
    [ -f "$file" ] && source "$file" || echo "File $file not found"
done

export GRADIO_TEMP_DIR="$HOME/tmp"
mkdir -p "$GRADIO_TEMP_DIR"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE="$HOME/miniforge3/bin/mamba";
export MAMBA_ROOT_PREFIX="$HOME/miniforge3";
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
