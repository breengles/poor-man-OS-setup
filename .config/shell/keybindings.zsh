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

# Line deletion (Cmd+Backspace)
bindkey "^U" kill-whole-line # Cmd+Backspace
