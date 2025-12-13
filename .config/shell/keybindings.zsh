autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search

autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

# Word navigation (Alt+Left, Alt+Right)
bindkey "^[b" backward-word # Alt+Left (from kitty mapping)
bindkey "^[f" forward-word # Alt+Right (from kitty mapping)

# Word deletion (Alt+Backspace)
bindkey "^[^?" backward-kill-word # Alt+Backspace

# Line navigation (Cmd+Left, Cmd+Right)
bindkey "^A" beginning-of-line # Cmd+Left (from kitty mapping)
bindkey "^E" end-of-line # Cmd+Right (from kitty mapping)


# Fuzzy find file and open in vim (Ctrl+P)
fzf-vim-widget() {
  local file
  file=$(command fd --type f --hidden --exclude .git 2>/dev/null | fzf --preview '[[ -f {} ]] && bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || head -500 {}')
  if [[ -n "$file" ]]; then
    BUFFER="vim $file"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N fzf-vim-widget
bindkey "^O" fzf-vim-widget

# Fuzzy search file contents and open in vim at line (Ctrl+G)
fzf-grep-vim-widget() {
  local selection file line
  selection=$(rg --color=always --line-number --no-heading --smart-case '' 2>/dev/null | \
    fzf --ansi --delimiter ':' \
        --preview 'bat --color=always --highlight-line {2} --line-range={2}:+100 {1} 2>/dev/null' \
        --preview-window 'up,60%')
  if [[ -n "$selection" ]]; then
    file=$(echo "$selection" | cut -d':' -f1)
    line=$(echo "$selection" | cut -d':' -f2)
    BUFFER="vim +$line $file"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N fzf-grep-vim-widget
bindkey "^G" fzf-grep-vim-widget

# Fuzzy find file and open in Cursor (Alt+O)
fzf-cursor-widget() {
  local file
  file=$(command fd --type f --hidden --exclude .git 2>/dev/null | fzf --preview '[[ -f {} ]] && bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || head -500 {}')
  if [[ -n "$file" ]]; then
    BUFFER="cursor $file"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N fzf-cursor-widget
bindkey "^[o" fzf-cursor-widget

# Fuzzy search file contents and open in Cursor at line (Alt+G)
fzf-grep-cursor-widget() {
  local selection file line
  selection=$(rg --color=always --line-number --no-heading --smart-case '' 2>/dev/null | \
    fzf --ansi --delimiter ':' \
        --preview 'bat --color=always --highlight-line {2} --line-range={2}:+100 {1} 2>/dev/null' \
        --preview-window 'up,60%')
  if [[ -n "$selection" ]]; then
    file=$(echo "$selection" | cut -d':' -f1)
    line=$(echo "$selection" | cut -d':' -f2)
    BUFFER="cursor -g $file:$line"
    zle accept-line
  fi
  zle reset-prompt
}
zle -N fzf-grep-cursor-widget
bindkey "^[g" fzf-grep-cursor-widget
