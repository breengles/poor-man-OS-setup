#!/usr/bin/env zsh
# Generic tmux window picker with a live preview.
#
#   tml                              fzf picker across every tmux window
#
# Same live-preview mechanism as `ccl` (see claude-tmux.zsh), but scoped
# to all sessions instead of just `claude/*` contexts.
#
# Preview: live snapshot of the target window's active pane via
# `tmux capture-pane -ep`, refreshed every TML_PREVIEW_REFRESH_S seconds.
# The preview command is a `while :` loop; fzf kills the old preview
# subprocess on every selection change, so cost is bounded.
#
# List auto-refresh: the `load` event fires after the input stream
# completes; we bind it to `reload(sleep N; list_cmd)`, which refills the
# list and re-triggers `load`. This makes newly created windows appear
# automatically every TML_LIST_REFRESH_S seconds.
#
# Manual refresh: `ctrl-r` reloads the list + preview immediately.
#
# Preview scrolling: shift-up/shift-down (fzf defaults).
# Jumps to session:window_index via `switch-client` (inside tmux) or
# `attach + select-window` (outside tmux).
tml() {
  emulate -L zsh
  local preview_s="${TML_PREVIEW_REFRESH_S:-2}"
  local list_s="${TML_LIST_REFRESH_S:-2}"

  # Shell command that produces the picker's rows. Kept as a single-quoted
  # zsh string so we can pass it verbatim to fzf's `reload(...)` actions.
  # `'\''` is the standard dance to embed a literal `'` inside single quotes.
  #
  # Columns:
  #   1. target         session:window_index  (jump target; also encodes session)
  #   2. window         window name (with `*` suffix when active)
  #   3. [cmd]          current pane command
  #   4. Np             pane count
  #   5. path           pane_current_path with $HOME collapsed to `~`
  #
  # The session name column is intentionally omitted: it's already the
  # prefix of the target, and duplicating it consumed too much width.
  local list_cmd='tmux list-windows -a -F "#{session_name}:#{window_index}|#{window_name}|#{pane_current_command}|#{window_panes}|#{pane_current_path}|#{?window_active,*, }" 2>/dev/null | awk -F"|" '\''{ p=$5; sub(ENVIRON["HOME"],"~",p); printf "%-20s  %-20s  [%-10s]  %sp  %s\n", $1, $2 $6, $3, $4, p }'\'''

  # Auto-refreshing preview: clear-screen + home-cursor ANSI between frames
  # so fzf (with --ansi) just overpaints the preview area.
  local preview_cmd='while :; do
  out=$(tmux capture-pane -ep -t {1} 2>/dev/null) || { echo "(window gone)"; exit 0; }
  printf "\033[2J\033[H%s" "$out"
  sleep '"$preview_s"'
done'

  local pick target session
  pick=$(sh -c "$list_cmd" \
    | fzf --ansi \
          --height 90% --reverse --prompt='tmux > ' \
          --preview "$preview_cmd" \
          --preview-window 'right,50%,wrap' \
          --bind "load:reload(sleep $list_s; $list_cmd)" \
          --bind "ctrl-r:reload($list_cmd)+refresh-preview") || return

  target="${pick%% *}"
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$target"
  else
    session="${target%%:*}"
    tmux attach -t "=$session" \; select-window -t "$target"
  fi
}
