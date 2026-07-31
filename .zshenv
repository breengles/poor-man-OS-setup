# Keep completion initialization under the user configuration's control.
# Ubuntu otherwise runs compinit before Zinit adds plugin completion paths.
export skip_global_compinit=1

[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
