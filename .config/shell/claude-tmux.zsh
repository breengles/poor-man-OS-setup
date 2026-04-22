#!/usr/bin/env zsh
# Claude Code tmux launchers.
#
#   ccs [suffix]   smart: ccp in a git repo, cct otherwise
#   ccp [suffix]   project context -> claude/<proj>/<suffix|branch|main>
#   cct [id]       temp context    -> claude/temp/<id|HHMMSS>
#   ccl            fzf picker across all claude/* contexts
#
# A "context" is a tmux window in the current session when invoked from
# inside tmux, or a dedicated tmux session otherwise. Contexts survive
# `claude` exiting: claude runs as a command inside the shell (via
# send-keys), so the shell remains after claude exits.
#
# `/` is used as the name separator (tmux names are free-form strings;
# tmux target syntax delimits session/window with `:` and window/pane
# with `.`, not `/`). We force exact-match `=name` on every tmux target
# lookup to avoid accidental prefix-matching.

# Normalize a name for tmux: drop characters that collide with tmux
# target syntax (`:` session/window, `.` window/pane) or look confusing
# in shell (spaces). `/` is kept on purpose as our separator.
_claude_sanitize() { print -r -- "${1//[.: ]/_}" }

# Create-or-select a claude context with the given name.
#   inside tmux  -> window named $name in the current session
#   outside tmux -> dedicated session named $name
#
# claude runs as the pane's initial command (not typed via send-keys),
# so nothing is echoed at a shell prompt and there is no race against
# shell startup. When claude exits, `exec zsh -i` replaces the process
# with a fresh interactive shell -- the context survives.
_claude_go() {
  local name="$1" cwd="$2" win_id
  local startup="zsh -ic 'claude; exec zsh -i'"
  if [[ -n "$TMUX" ]]; then
    if tmux list-windows -F '#W' 2>/dev/null | grep -qxF "$name"; then
      tmux select-window -t "=$name"
      return
    fi
    if [[ -n "$cwd" ]]; then
      win_id=$(tmux new-window -d -P -F '#{window_id}' -n "$name" -c "$cwd" "$startup")
    else
      win_id=$(tmux new-window -d -P -F '#{window_id}' -n "$name" "$startup")
    fi
    tmux select-window -t "$win_id"
  else
    if tmux has-session -t "=$name" 2>/dev/null; then
      tmux attach -t "=$name"
      return
    fi
    if [[ -n "$cwd" ]]; then
      tmux new -ds "$name" -c "$cwd" "$startup"
    else
      tmux new -ds "$name" "$startup"
    fi
    tmux attach -t "=$name"
  fi
}

cct() {
  local id="${1:-$(date +%H%M%S)}"
  local name
  name=$(_claude_sanitize "claude/temp/${id}")
  _claude_go "$name"
}

ccp() {
  local root proj branch suffix name
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root="$PWD"
  proj="${root##*/}"
  branch=$(git -C "$root" symbolic-ref --short HEAD 2>/dev/null)
  suffix="${1:-${branch:-main}}"
  name=$(_claude_sanitize "claude/${proj}/${suffix}")
  _claude_go "$name" "$root"
}

ccs() {
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    ccp "$@"
  else
    cct "$@"
  fi
}

# fzf picker over every claude/* context: windows whose session name
# starts with claude/ (outside-tmux launches) and windows whose window
# name starts with claude/ (inside-tmux launches).
# Jumps to session:window_index. Pane navigation inside a window stays
# tmux-native (M-hjkl in this setup).
ccl() {
  local pick target session
  pick=$(tmux list-windows -a \
          -F '#{session_name}:#{window_index}|#{session_name}|#{window_name}|#{pane_current_command}|#{window_panes}|#{pane_current_path}' \
          2>/dev/null \
        | awk -F'|' '$2 ~ /^claude\// || $3 ~ /^claude\// { printf "%-40s  ses=%-28s  win=%-28s  [%s]  (%sp)  %s\n", $1, $2, $3, $4, $5, $6 }' \
        | fzf --height 40% --reverse --prompt='claude > ') || return
  target="${pick%% *}"
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$target"
  else
    session="${target%%:*}"
    tmux attach -t "=$session" \; select-window -t "$target"
  fi
}

# ---------- zsh completion ----------

_claude_list_names() {
  # Emit names of existing claude/* contexts:
  #   - tmux sessions (visible everywhere)
  #   - tmux windows in the current session (inside-tmux launches)
  tmux ls -F '#{session_name}' 2>/dev/null
  [[ -n "$TMUX" ]] && tmux list-windows -F '#W' 2>/dev/null
}

_cct() {
  local -a existing
  existing=(${(f)"$(_claude_list_names | sed -n 's|^claude/temp/||p' | sort -u)"})
  _describe 'existing temp' existing
}
compdef _cct cct

_ccp() {
  local root proj
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  proj=$(_claude_sanitize "${root##*/}")

  local -a existing branches
  existing=(${(f)"$(_claude_list_names | sed -n "s|^claude/${proj}/||p" | sort -u)"})
  branches=(${(f)"$(git -C "$root" for-each-ref \
                    --format='%(refname:short)' refs/heads/ 2>/dev/null)"})

  _describe 'existing session/window' existing
  _describe 'branch' branches
}
compdef _ccp ccp

_ccs() {
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    _ccp
  else
    _cct
  fi
}
compdef _ccs ccs
