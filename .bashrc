# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return ;;
esac

# ---------------------------------------------------------------------------
# Trampoline: prefer zsh when available.
# On machines where chsh is unavailable, bash starts first and exec's zsh.
# Add hostname prefixes below to keep bash (e.g. nodes that break under exec).
# ---------------------------------------------------------------------------
_no_zsh_patterns=(
  "login-"
)

_use_zsh=true
_hostname=$(hostname)
for _pat in "${_no_zsh_patterns[@]}"; do
  case "$_hostname" in
    ${_pat}*) _use_zsh=false; break ;;
  esac
done

zsh_path=$(command -v zsh)
if [ "$_use_zsh" = true ] && [ -x "$zsh_path" ] && [ "$SHELL" != "$zsh_path" ]; then
  export SHELL="$zsh_path"
  exec zsh
fi
unset _no_zsh_patterns _use_zsh _hostname _pat zsh_path

# ---------------------------------------------------------------------------
# Bash configuration (only reached if the trampoline didn't fire)
# ---------------------------------------------------------------------------
shopt -s checkwinsize

source "$HOME/.config/shell/env_vars.sh"
source "$HOME/.config/shell/history.bash"
source "$HOME/.config/shell/keybindings.bash"
source "$HOME/.config/shell/completions.bash"
source "$HOME/.config/shell/functions.sh"
source "$HOME/.config/shell/aliases.sh"
source "$HOME/.config/shell/integrations.sh"
