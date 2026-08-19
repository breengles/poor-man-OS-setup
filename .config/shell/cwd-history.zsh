# Directory-prioritized command history.
#
# Every interactive command is logged with the directory it ran in. Ctrl-R and
# the zsh-autosuggestions suggestion are then ranked so commands from the
# current directory come first, with the rest of the history still reachable
# below them.
#
# Zsh's own history is untouched. This is a parallel log, so removing this
# module restores stock behavior with no cleanup.
#
# Ordering matters: this file must be sourced AFTER integrations.sh (which
# sources ~/.fzf.zsh and binds ^R to fzf-history-widget) and AFTER zinit.zsh
# (which loads zsh-autosuggestions and defaults ZSH_AUTOSUGGEST_STRATEGY).

CWD_HISTORY_FILE="${CWD_HISTORY_FILE:-$HOME/.local/share/cwd-history.tsv}"
CWD_HISTORY_SEED_FILE="${CWD_HISTORY_SEED_FILE:-$CWD_HISTORY_FILE.seed}"
CWD_HISTORY_MAX="${CWD_HISTORY_MAX:-100000}"             # records kept on disk
CWD_HISTORY_CACHE_MAX="${CWD_HISTORY_CACHE_MAX:-20000}"  # newest records held in memory
CWD_HISTORY_CACHE_BYTES="${CWD_HISTORY_CACHE_BYTES:-1048576}"  # read the tail past this

# Records are TAB-separated: directory, then command. A command can contain
# neither byte, because newline and tab are swapped for SOH and STX on the way
# in and swapped back on the way out. Both markers are single characters, so
# neither substitution can manufacture the other's marker and the round trip is
# unambiguous in either direction.
typeset -g _cwd_history_nl=$'\x01'
typeset -g _cwd_history_tab=$'\x02'

CWD_HISTORY_AWK="${CWD_HISTORY_AWK:-${0:A:h}/cwd-history.awk}"

autoload -Uz add-zsh-hook

#--------------------------------------------------------------------#
# Seed                                                               #
#--------------------------------------------------------------------#

# Without this the picker looks empty on day one. Seeded entries get "-" as
# their directory, which matches no tier test, so they sort to the bottom
# forever. Multi-line entries seed as separate lines; not worth solving.
# The import lives in its own file because the cache re-reads the live log on
# every cd. Seeded records carry no directory, so they can never match a tier
# test, and letting thousands of them sit in the hot path cost 7ms per cd.
# Only the ranker reads this file.
if [[ ! -e $CWD_HISTORY_SEED_FILE ]]; then
  mkdir -p ${CWD_HISTORY_SEED_FILE:h}
  : >| $CWD_HISTORY_SEED_FILE
  # $HISTFILE is read directly rather than through fc: zsh has not loaded the
  # history list yet this early in .zshrc, and forcing it with `fc -R` would
  # duplicate every entry once zsh loads the file itself. Handles both the
  # plain and the EXTENDED_HISTORY ": <ts>:<elapsed>;<cmd>" line formats.
  # LC_ALL=C because zsh metafies non-ASCII bytes in the history file and
  # macOS awk aborts the whole run on the first multibyte conversion failure.
  # Both awk calls in this file need it. fzf's own shell code does the same.
  [[ -r $HISTFILE ]] && LC_ALL=C command awk '
    { sub(/^: [0-9]+:[0-9]+;/, ""); if (NF) print "-\t" $0 }
  ' $HISTFILE >| $CWD_HISTORY_SEED_FILE
fi
[[ -e $CWD_HISTORY_FILE ]] || { mkdir -p ${CWD_HISTORY_FILE:h}; : >| $CWD_HISTORY_FILE }

#--------------------------------------------------------------------#
# Record                                                             #
#--------------------------------------------------------------------#

# Newest first, deduped, commands run in $PWD. Kept in memory so the
# autosuggestion strategy never forks on a keystroke.
typeset -ga _cwd_history_here

_cwd_history_load() {
  emulate -L zsh
  _cwd_history_here=()
  [[ -r $CWD_HISTORY_FILE ]] || return 0

  # Reading and splitting the whole log is the expensive part and it runs on
  # every cd, so cap it by file size first. Under the cap $(<file) is a builtin
  # read with no fork; over it, one tail fork beats splitting a huge array.
  local -a lines here
  local -a st
  zmodload -F zsh/stat b:zstat 2>/dev/null && zstat -A st +size $CWD_HISTORY_FILE 2>/dev/null
  if (( ${st[1]:-0} > CWD_HISTORY_CACHE_BYTES )); then
    lines=( ${(f)"$(command tail -n $CWD_HISTORY_CACHE_MAX $CWD_HISTORY_FILE)"} )
  else
    lines=( ${(f)"$(<$CWD_HISTORY_FILE)"} )
    (( $#lines > CWD_HISTORY_CACHE_MAX )) && lines=( ${lines[-CWD_HISTORY_CACHE_MAX,-1]} )
  fi

  here=( ${${(M)lines:#${(b)PWD}$'\t'*}#*$'\t'} )
  here=( ${(u)${(Oa)here}} )
  _cwd_history_here=( ${${here//$_cwd_history_nl/$'\n'}//$_cwd_history_tab/$'\t'} )
}

_cwd_history_record() {
  emulate -L zsh
  local cmd=$1

  # Agent shells would skew the ranking with commands the user never typed.
  # Same guard aliases.sh uses to suppress eza/bat.
  [[ -n $AGENT || -n $CLAUDECODE ]] && return 0
  [[ $cmd == ' '* ]] && return 0            # parity with hist_ignore_space
  [[ -z ${cmd//[[:space:]]/} ]] && return 0

  local esc=${${cmd//$'\n'/$_cwd_history_nl}//$'\t'/$_cwd_history_tab}

  # One short write to an O_APPEND fd, so concurrent tmux panes interleave
  # cleanly without locking. $'..' does not expand inside double quotes, so the
  # separator has to come in through a parameter.
  local tab=$'\t'
  print -r -- "$PWD$tab$esc" >> $CWD_HISTORY_FILE 2>/dev/null

  _cwd_history_here=( $cmd ${(@)_cwd_history_here:#${(b)cmd}} )
}

add-zsh-hook preexec _cwd_history_record
add-zsh-hook chpwd _cwd_history_load

#--------------------------------------------------------------------#
# Rank                                                               #
#--------------------------------------------------------------------#

# Four tiers, printed in order, newest first inside each. Dedup is global and
# keeps a command in its best tier, so nothing repeats further down.
#
#   0  exactly $PWD
#   1  below $PWD
#   2  elsewhere in this git repo
#   3  everything else
#
# NUL-separated on stdout so multi-line commands survive intact into fzf --read0.
_cwd_history_rank() {
  emulate -L zsh
  [[ -r $CWD_HISTORY_FILE && -r $CWD_HISTORY_AWK ]] || return 0

  local seed=$CWD_HISTORY_SEED_FILE
  [[ -r $seed ]] || seed=/dev/null

  local root
  root=$(command git rev-parse --show-toplevel 2>/dev/null) || root=

  LC_ALL=C command awk -v P="$PWD" -v R="$root" -v T="${1:-3}" \
                       -v NL="$_cwd_history_nl" -v TB="$_cwd_history_tab" \
                       -f $CWD_HISTORY_AWK $seed $CWD_HISTORY_FILE
}

# The same call as a plain string, for fzf's reload bindings. fzf runs these
# through sh, which knows nothing about zsh functions, so the awk invocation
# has to be spelled out and quoted here.
_cwd_history_rank_cmd() {
  emulate -L zsh
  local seed=$CWD_HISTORY_SEED_FILE
  [[ -r $seed ]] || seed=/dev/null
  local root
  root=$(command git rev-parse --show-toplevel 2>/dev/null) || root=
  print -r -- "LC_ALL=C awk -v P=${(q)PWD} -v R=${(q)root} -v T=$1 \
    -v NL=${(q)_cwd_history_nl} -v TB=${(q)_cwd_history_tab} \
    -f ${(q)CWD_HISTORY_AWK} ${(q)seed} ${(q)CWD_HISTORY_FILE}"
}

#--------------------------------------------------------------------#
# Ctrl-R                                                             #
#--------------------------------------------------------------------#

cwd-history-widget() {
  local selected
  setopt localoptions pipefail no_aliases noglob

  # --no-sort is what makes the tiers mean anything: fzf narrows the list as
  # you type but leaves the surviving lines in the order given. ctrl-r inside
  # the picker toggles back to fzf's own relevance sort.
  local e=$'\e' g0 g1 g2 g3
  g0="${e}[48;5;35m ${e}[0m"; g1="${e}[48;5;39m ${e}[0m"
  g2="${e}[48;5;178m ${e}[0m"; g3="${e}[48;5;240m ${e}[0m"

  # Scope cycles on ^R itself. tmux binds M-1..M-9 to window switching, so alt
  # digits never reach fzf here. Cycling also matches what ^R already means:
  # press it again to widen the search.
  local -x CWDH_C0 CWDH_C1 CWDH_C2 CWDH_C3 CWDH_H0 CWDH_H1 CWDH_H2 CWDH_H3
  CWDH_C0=$(_cwd_history_rank_cmd 0); CWDH_C1=$(_cwd_history_rank_cmd 1)
  CWDH_C2=$(_cwd_history_rank_cmd 2); CWDH_C3=$(_cwd_history_rank_cmd 3)
  CWDH_H0="$g0 here"
  CWDH_H1="$g0 here $g1 below"
  CWDH_H2="$g0 here $g1 below $g2 repo"
  CWDH_H3="$g0 here $g1 below $g2 repo $g3 global"

  # fzf exports FZF_PROMPT to transform actions, so the prompt carries the
  # scope and no state file is needed.
  local cycle='case "$FZF_PROMPT" in
      "all> ")    echo "reload($CWDH_C0)+change-prompt(here> )+change-header($CWDH_H0)" ;;
      "here> ")   echo "reload($CWDH_C1)+change-prompt(below> )+change-header($CWDH_H1)" ;;
      "below> ")  echo "reload($CWDH_C2)+change-prompt(repo> )+change-header($CWDH_H2)" ;;
      *)          echo "reload($CWDH_C3)+change-prompt(all> )+change-header($CWDH_H3)" ;;
    esac'

  selected=$(
    _cwd_history_rank | FZF_DEFAULT_OPTS_FILE='' fzf \
      --read0 --no-sort --height ${FZF_TMUX_HEIGHT:-40%} --min-height 20+ \
      --reverse --highlight-line --wrap --wrap-sign '  ' \
      --ansi --delimiter=$'\t' --nth=2.. \
      --prompt='all> ' --header="$CWDH_H3  --  ^R narrows scope, ^T sorts" \
      --bind=ctrl-z:ignore --bind=ctrl-t:toggle-sort \
      --bind="ctrl-r:transform:$cycle" \
      --query=$LBUFFER +m ${=FZF_CTRL_R_OPTS}
  )
  local ret=$?

  # Drop the gutter cell and its delimiter. Only the first tab is the
  # delimiter, so a command containing a real tab survives intact.
  [[ -n $selected ]] && selected=${selected#*$'\t'}

  if [[ -n $selected ]]; then
    BUFFER=$selected
    CURSOR=${#BUFFER}
  fi
  zle reset-prompt
  return $ret
}

if (( $+commands[fzf] )); then
  zle -N cwd-history-widget
  bindkey -M emacs '^R' cwd-history-widget
  bindkey -M viins '^R' cwd-history-widget
  bindkey -M vicmd '^R' cwd-history-widget
fi

#--------------------------------------------------------------------#
# Autosuggestion                                                     #
#--------------------------------------------------------------------#

# Runs on every keystroke, so it may not fork: it is an array lookup against
# the in-memory cache, the same operation the builtin history strategy does
# against $history. Two tiers only. The suggestion is a single string, so the
# middle tiers would only break ties and are not worth the per-keystroke cost.
_zsh_autosuggest_strategy_cwd_history() {
  emulate -L zsh
  setopt EXTENDED_GLOB
  local prefix="${1//(#m)[\\*?[\]<>()|^~#]/\\$MATCH}"
  typeset -g suggestion="${_cwd_history_here[(r)${prefix}*]}"
}

# zsh-autosuggestions has already defaulted this to (history) by the time we
# get here, so prepend rather than test for unset.
if (( ${+ZSH_AUTOSUGGEST_STRATEGY} )); then
  # Both operands of && are expanded before the math is evaluated, so the
  # subscript test has to be nested rather than guarded on the same line.
  (( ${ZSH_AUTOSUGGEST_STRATEGY[(I)cwd_history]} )) ||
    ZSH_AUTOSUGGEST_STRATEGY=( cwd_history $ZSH_AUTOSUGGEST_STRATEGY )
fi

#--------------------------------------------------------------------#
# Prune                                                              #
#--------------------------------------------------------------------#

# Rewrites only once the file is 20% over the cap, so a daily check is almost
# always a single wc.
_cwd_history_prune() {
  emulate -L zsh
  [[ -r $CWD_HISTORY_FILE && -w $CWD_HISTORY_FILE ]] || return 0
  local n=$(command wc -l < $CWD_HISTORY_FILE)
  (( n > CWD_HISTORY_MAX * 12 / 10 )) || return 0
  local tmp=$CWD_HISTORY_FILE.$$
  command tail -n $CWD_HISTORY_MAX $CWD_HISTORY_FILE > $tmp \
    && command mv -f $tmp $CWD_HISTORY_FILE \
    || command rm -f $tmp
}

(( ${+PERIOD} )) || PERIOD=86400
add-zsh-hook periodic _cwd_history_prune

_cwd_history_load
