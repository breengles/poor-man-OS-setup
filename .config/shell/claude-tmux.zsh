#!/usr/bin/env zsh
# Claude Code tmux launchers.
#
#   ccs [-n NAME] [claude_args...]   smart: ccp in a git repo, cct otherwise
#   ccp [-n NAME] [claude_args...]   project context -> claude/<proj>/<NAME|branch|main>
#   cct [-n NAME] [claude_args...]   temp context    -> claude/temp/<NAME|HHMMSS>
#   ccl                              fzf picker across all claude/* contexts
#
# -n / --name overrides the default context name. Everything else is
# forwarded verbatim to `claude` on first launch. `--` is accepted as an
# explicit end-of-options terminator if you need to pass a positional
# argument that happens to look like one of our flags.
#
#   ccs                          -> claude          (ctx = branch or HHMMSS)
#   ccs -r                       -> claude -r
#   ccs --resume abc123          -> claude --resume abc123
#   ccs -n review -r             -> claude -r       (ctx = claude/<proj>/review)
#   cct -n scratch -c            -> claude -c       (ctx = claude/temp/scratch)
#   ccs -- -n                    -> claude -n       (literal -n passed through)
#
# Note: claude args are honored only when the context is first created.
# If the target window/session already exists we just attach to it.
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
  local name="$1" cwd="$2"
  shift 2
  local -a claude_args=("$@")
  local win_id

  # Build `zsh -ic '<cmd>'` safely. `${(q)claude_args[@]}` shell-quotes each
  # arg; `${(q)inner}` wraps the whole pipeline for tmux's command string.
  local inner="claude"
  (( $#claude_args )) && inner+=" ${(q)claude_args[@]}"
  inner+="; exec zsh -i"
  local startup="zsh -ic ${(q)inner}"

  if [[ -n "$TMUX" ]]; then
    if tmux list-windows -F '#W' 2>/dev/null | grep -qxF "$name"; then
      (( $#claude_args )) && print -u2 -- "ccs: window '$name' exists; claude args ignored (attach only)"
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
      (( $#claude_args )) && print -u2 -- "ccs: session '$name' exists; claude args ignored (attach only)"
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

# Parse args: extract `-n NAME` / `--name NAME` / `--name=NAME` into
# `ctx_name`; everything else is forwarded to `claude`. `--` ends option
# parsing (everything after is treated as claude args). Writes into the
# caller's `ctx_name` scalar and `claude_args` array (must be declared).
_claude_parse_args() {
  ctx_name=""
  claude_args=()
  while (( $# )); do
    case "$1" in
      -n|--name)
        if (( $# < 2 )); then
          print -u2 -- "ccs: $1 requires an argument"
          return 1
        fi
        ctx_name="$2"
        shift 2
        ;;
      --name=*)
        ctx_name="${1#--name=}"
        shift
        ;;
      --)
        shift
        claude_args+=("$@")
        break
        ;;
      *)
        claude_args+=("$1")
        shift
        ;;
    esac
  done
}

cct() {
  local ctx_name
  local -a claude_args
  _claude_parse_args "$@" || return
  local id="${ctx_name:-$(date +%H%M%S)}"
  local name
  name=$(_claude_sanitize "claude/temp/${id}")
  _claude_go "$name" "" "${claude_args[@]}"
}

ccp() {
  local ctx_name
  local -a claude_args
  _claude_parse_args "$@" || return
  local root proj branch suffix name
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root="$PWD"
  proj="${root##*/}"
  branch=$(git -C "$root" symbolic-ref --short HEAD 2>/dev/null)
  suffix="${ctx_name:-${branch:-main}}"
  name=$(_claude_sanitize "claude/${proj}/${suffix}")
  _claude_go "$name" "$root" "${claude_args[@]}"
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
#
# Preview: live snapshot of the target window's active pane via
# `tmux capture-pane -ep`, refreshed every CCL_PREVIEW_REFRESH_S seconds.
# The preview command is a `while :` loop; fzf kills the old preview
# subprocess on every selection change, so cost is bounded.
#
# List auto-refresh: the `load` event fires after the input stream
# completes; we bind it to `reload(sleep N; list_cmd)`, which refills the
# list and re-triggers `load`. This makes newly created claude/* contexts
# appear automatically every CCL_LIST_REFRESH_S seconds.
#
# Manual refresh: `ctrl-r` reloads the list + preview immediately.
#
# Preview scrolling: shift-up/shift-down (fzf defaults).
# Jumps to session:window_index. Pane navigation inside a window stays
# tmux-native (M-hjkl in this setup).
ccl() {
  emulate -L zsh
  local preview_s="${CCL_PREVIEW_REFRESH_S:-2}"
  local list_s="${CCL_LIST_REFRESH_S:-2}"

  # Shell command that produces the picker's rows. Kept as a single-quoted
  # zsh string so we can pass it verbatim to fzf's `reload(...)` actions.
  # `'\''` is the standard dance to embed a literal `'` inside single quotes.
  #
  # Columns:
  #   1. target         session:window_index  (jump target)
  #   2. name           claude/<...>  -- from session (outside-tmux) or window
  #                     name (inside-tmux), whichever starts with `claude/`
  #   3. [cmd]          current pane command
  #   4. (Np)           pane count
  #   5. path           pane_current_path with $HOME collapsed to `~`
  local list_cmd='tmux list-windows -a -F "#{session_name}:#{window_index}|#{session_name}|#{window_name}|#{pane_current_command}|#{window_panes}|#{pane_current_path}" 2>/dev/null | awk -F"|" '\''$2 ~ /^claude\// || $3 ~ /^claude\// { name=($3 ~ /^claude\//)?$3:$2; p=$6; sub(ENVIRON["HOME"],"~",p); printf "%-22s  %-40s  [%-10s]  (%sp)  %s\n", $1, name, $4, $5, p }'\'''

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
          --height 90% --reverse --prompt='claude > ' \
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

# ---------- zsh completion ----------

_claude_list_names() {
  # Emit names of existing claude/* contexts:
  #   - tmux sessions (visible everywhere)
  #   - tmux windows in the current session (inside-tmux launches)
  tmux ls -F '#{session_name}' 2>/dev/null
  [[ -n "$TMUX" ]] && tmux list-windows -F '#W' 2>/dev/null
}

# Candidate names for `cct -n <TAB>`: existing claude/temp/* contexts.
_cct_names() {
  local -a existing
  existing=(${(f)"$(_claude_list_names | sed -n 's|^claude/temp/||p' | sort -u)"})
  _describe 'existing temp' existing
}

# Candidate names for `ccp -n <TAB>`: existing claude/<proj>/* + local branches.
_ccp_names() {
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

_cct() {
  _arguments -S \
    '(-n --name)'{-n,--name}'[context name]:name:_cct_names' \
    '*::claude args: '
}
compdef _cct cct

_ccp() {
  _arguments -S \
    '(-n --name)'{-n,--name}'[context name]:name:_ccp_names' \
    '*::claude args: '
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
