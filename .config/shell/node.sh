# ---------------------------------------------------------------------------
# Node via nvm: put the default version's bin directory straight on PATH.
#
# Running node does not need nvm loaded -- `nvm use` only prepends a directory
# to PATH. Sourcing nvm.sh is ~70ms and `nvm use default` another ~500ms (worse
# when $HOME is on a network filesystem), so node/npm/npx used to be lazy-load
# shim functions calling a shared _load_nvm helper. That broke under AI agent
# harnesses: Claude Code snapshots the interactive shell's functions but drops
# underscore-prefixed ones, so the `node` shim survived while its helper did
# not. Every node/npx call then died with "_load_nvm: command not found", or -
# where no shim existed at all - silently fell through to a distro node v10.
#
# Resolving the version directory with globs instead costs ~4ms and needs no
# shims, so node works identically in interactive shells, scripts and agents.
# `nvm` itself is still lazy: it is only needed to install or switch versions.
# ---------------------------------------------------------------------------

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -d "$NVM_DIR/versions/node" ]; then
  # Resolve the `default` alias to a version, following lts/* indirection.
  __nvm_alias=default
  __nvm_target=
  __nvm_hops=0
  while [ -r "$NVM_DIR/alias/$__nvm_alias" ] && [ "$__nvm_hops" -lt 5 ]; do
    read -r __nvm_target < "$NVM_DIR/alias/$__nvm_alias" || break
    case "$__nvm_target" in
      lts/* | default) __nvm_alias=$__nvm_target; __nvm_hops=$((__nvm_hops + 1)) ;;
      *) break ;;
    esac
  done

  case "$__nvm_target" in
    v*) __nvm_ver=$__nvm_target ;;
    # No usable alias (or it points at the system node): take the newest install.
    '' | node | stable | unstable | iojs | system) __nvm_ver= ;;
    *) __nvm_ver=v$__nvm_target ;;
  esac

  # A bare major like "22" needs a prefix match; only then pay for the sort.
  # `command` prefixes matter: this file is sourced after aliases.sh, and an
  # interactive `ls --color` alias would inject escape codes into the path.
  # The outer redirect swallows zsh's "no matches found" on an unmatched glob;
  # bash instead passes the pattern through, hence the final -d check.
  if [ -n "$__nvm_ver" ] && [ -d "$NVM_DIR/versions/node/$__nvm_ver/bin" ]; then
    __nvm_bin=$NVM_DIR/versions/node/$__nvm_ver/bin
  else
    { __nvm_bin=$(command printf '%s\n' "$NVM_DIR/versions/node/$__nvm_ver"*/bin |
      command sort -V | command tail -1); } 2>/dev/null
    [ -d "$__nvm_bin" ] || __nvm_bin=
  fi

  if [ -n "$__nvm_bin" ]; then
    case ":$PATH:" in
      *":$__nvm_bin:"*) ;;
      *) PATH="$__nvm_bin:$PATH" ;;
    esac
    export PATH
    # nvm exports these on `nvm use`; keep them consistent for tools that read
    # them and for a later `nvm use <other>` in the same shell.
    export NVM_BIN="$__nvm_bin"
    export NVM_INC="${__nvm_bin%/bin}/include/node"
  fi

  unset __nvm_alias __nvm_target __nvm_hops __nvm_ver __nvm_bin
fi

# Deliberately self-contained: no underscore-prefixed helper, since harnesses
# that snapshot shell functions drop those and leave a broken shim behind.
nvm() {
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm is not installed under $NVM_DIR" >&2
    return 127
  fi
  unset -f nvm
  # --no-use: PATH already points at the default version.
  . "$NVM_DIR/nvm.sh" --no-use
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  nvm "$@"
}
