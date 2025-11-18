### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light Aloxaf/fzf-tab
# zinit light zsh-users/zsh-syntax-highlighting
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Add zinit snippets
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load completions with caching (only rebuild once per day)
autoload -Uz compinit
setopt EXTENDEDGLOB
local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

# Rebuild completion cache only once per day
if [[ -n ${zcompdump}(#qN.mh+24) ]]; then
  # Dump file is older than 24 hours, rebuild it
  compinit
else
  # Use cached version, skip security check with -C
  compinit -C
fi
unsetopt EXTENDEDGLOB

zinit cdreplay -q
