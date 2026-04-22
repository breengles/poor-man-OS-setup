#!/usr/bin/env zsh
# Claude Code tmux session launchers.
#
#   ccs [suffix]   smart: ccp in a git repo, cct otherwise
#   ccp [suffix]   project session -> claude-<proj>-<suffix|branch|main>
#   cct [id]       temp session    -> claude-temp-<id|HHMMSS>
#   ccl            fzf picker across all claude-* sessions
#
# Sessions survive `claude` exiting: claude runs as a command inside the
# session's shell (via send-keys), so the shell remains after claude exits.

_claude_sanitize() { print -r -- "${1//[.:\/ ]/_}" }

_claude_enter() {
  local ses="$1"
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$ses"
  else
    tmux attach -t "$ses"
  fi
}

_claude_ensure() {
  local ses="$1" cwd="$2"
  if ! tmux has-session -t "$ses" 2>/dev/null; then
    if [[ -n "$cwd" ]]; then
      tmux new -ds "$ses" -c "$cwd"
    else
      tmux new -ds "$ses"
    fi
    tmux send-keys -t "$ses" "claude" Enter
  fi
}

cct() {
  local id="${1:-$(date +%H%M%S)}"
  local ses
  ses=$(_claude_sanitize "claude-temp-${id}")
  _claude_ensure "$ses"
  _claude_enter "$ses"
}

ccp() {
  local root proj branch suffix ses
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root="$PWD"
  proj="${root##*/}"
  branch=$(git -C "$root" symbolic-ref --short HEAD 2>/dev/null)
  suffix="${1:-${branch:-main}}"
  ses=$(_claude_sanitize "claude-${proj}-${suffix}")
  _claude_ensure "$ses" "$root"
  _claude_enter "$ses"
}

ccs() {
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    ccp "$@"
  else
    cct "$@"
  fi
}

ccl() {
  local ses
  ses=$(tmux ls -F '#{session_name}' 2>/dev/null \
        | grep '^claude-' \
        | fzf --height 40% --reverse --prompt='claude > ') || return
  _claude_enter "$ses"
}

# ---------- zsh completion ----------

_cct() {
  local -a sessions
  sessions=(${(f)"$(tmux ls -F '#{session_name}' 2>/dev/null \
                    | sed -n 's/^claude-temp-//p')"})
  _describe 'existing temp' sessions
}
compdef _cct cct

_ccp() {
  local root proj
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  proj=$(_claude_sanitize "${root##*/}")

  local -a existing branches
  existing=(${(f)"$(tmux ls -F '#{session_name}' 2>/dev/null \
                    | sed -n "s/^claude-${proj}-//p")"})
  branches=(${(f)"$(git -C "$root" for-each-ref \
                    --format='%(refname:short)' refs/heads/ 2>/dev/null)"})

  _describe 'existing session' existing
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
