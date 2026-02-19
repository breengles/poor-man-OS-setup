bind '"\e[A": history-search-backward'  # Up arrow
bind '"\e[B": history-search-forward'   # Down arrow

# Word navigation (Alt+Left, Alt+Right)
bind '"\eb": backward-word'             # Alt+Left (from kitty mapping)
bind '"\ef": forward-word'              # Alt+Right (from kitty mapping)

# Word deletion (Alt+Backspace)
bind '"\e\C-?": backward-kill-word'     # Alt+Backspace

# Line navigation (Cmd+Left, Cmd+Right)
bind '"\C-a": beginning-of-line'        # Cmd+Left (from kitty mapping)
bind '"\C-e": end-of-line'              # Cmd+Right (from kitty mapping)

# ---------------------------------------------------------------------------
# fzf widgets (Ctrl+O, Ctrl+G, Alt+O, Alt+G)
# Uses bind -x to run shell functions that set READLINE_LINE.
# ---------------------------------------------------------------------------

_fzf_open_file() {
  local editor="$1" file
  file=$(command fd --type f --hidden --exclude .git 2>/dev/null | \
    fzf --preview '[[ -f {} ]] && bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || head -500 {}')
  if [[ -n "$file" ]]; then
    READLINE_LINE="$editor $file"
    READLINE_POINT=${#READLINE_LINE}
  fi
}

_fzf_grep_open() {
  local editor="$1" selection file line
  selection=$(rg --hidden --color=always --line-number --no-heading --smart-case '' 2>/dev/null | \
    fzf --ansi --delimiter ':' \
        --preview 'bat --color=always --highlight-line {2} --line-range={2}:+100 {1} 2>/dev/null' \
        --preview-window 'up,60%')
  if [[ -n "$selection" ]]; then
    file=$(echo "$selection" | cut -d':' -f1)
    line=$(echo "$selection" | cut -d':' -f2)
    if [[ "$editor" == "cursor" ]]; then
      READLINE_LINE="cursor -g $file:$line"
    else
      READLINE_LINE="$editor +$line $file"
    fi
    READLINE_POINT=${#READLINE_LINE}
  fi
}

# Fuzzy find file and open in vim (Ctrl+O)
_fzf_vim_widget() { _fzf_open_file vim; }
bind -x '"\C-o": _fzf_vim_widget'

# Fuzzy search file contents and open in vim at line (Ctrl+G)
_fzf_grep_vim_widget() { _fzf_grep_open vim; }
bind -x '"\C-g": _fzf_grep_vim_widget'

# Fuzzy find file and open in Cursor (Alt+O)
_fzf_cursor_widget() { _fzf_open_file cursor; }
bind -x '"\eo": _fzf_cursor_widget'

# Fuzzy search file contents and open in Cursor at line (Alt+G)
_fzf_grep_cursor_widget() { _fzf_grep_open cursor; }
bind -x '"\eg": _fzf_grep_cursor_widget'
