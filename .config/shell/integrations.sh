#!/usr/bin/env bash
# Shared integrations for bash and zsh.
# Uses $ZSH_VERSION / $BASH_VERSION to pick shell-specific variants.

# Determine shell suffix for shell-specific integration files
if [ -n "$ZSH_VERSION" ]; then
  _sh="zsh"
else
  _sh="bash"
fi

# Cargo
if [ -f "$HOME/.cargo/env" ]; then source "$HOME/.cargo/env"; fi

# fzf
_fzf="$HOME/.fzf.${_sh}"
if [ -f "$_fzf" ]; then source "$_fzf"; fi

# Google Cloud SDK
_gcloud_path="$HOME/google-cloud-sdk/path.${_sh}.inc"
_gcloud_comp="$HOME/google-cloud-sdk/completion.${_sh}.inc"
if [ -f "$_gcloud_path" ]; then source "$_gcloud_path"; fi
if [ -f "$_gcloud_comp" ]; then source "$_gcloud_comp"; fi

# lesspipe (makes less handle non-text files)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Starship prompt
if [ -x "$(command -v starship)" ]; then
  eval "$(starship init "$_sh")"
fi

# Tokens / secrets
if [ -f "$HOME/.env-global.sh" ]; then source "$HOME/.env-global.sh"; fi

# Generate tab-completion script for a tool (stdout).
# Add new tools here as: tool) tool-specific-command ;;
_gen_completion() {
  local tool="$1" sh="$2"
  case "$tool" in
    delta)    delta --generate-completion "$sh" ;;
    glab)     glab completion -s "$sh" ;;
    rg)       rg --generate "complete-${sh}" ;;
    uv)       uv generate-shell-completion "$sh" ;;
    *)        return 1 ;;
  esac
}

# True if the cache file is missing or older than a week.
_completion_stale() {
  [ -f "$1" ] || return 0
  [ -n "$(find "$1" -mtime +7 2>/dev/null)" ]
}

# Tool completions, generated kind: cached at ~/.completion.<tool>.<shell> and
# refreshed weekly, so the cache follows the installed version. Regenerating all
# of them costs ~0.6s, paid once a week by whichever shell starts first.
# The generic .sh name is deliberately not consulted here: a leftover one used to
# shadow the shell-specific file forever, pinning uv's completion to a 2025 build
# whose `uv run` spec offered no completion for the command being run.
_completion_generated=(uv glab delta rg)
for _tool in "${_completion_generated[@]}"; do
  command -v "$_tool" >/dev/null 2>&1 || continue
  _comp_file="$HOME/.completion.${_tool}.${_sh}"
  if _completion_stale "$_comp_file"; then
    # Write to a temp file so a failed generator can't truncate a working cache.
    if _gen_completion "$_tool" "$_sh" > "${_comp_file}.new" 2>/dev/null && [ -s "${_comp_file}.new" ]; then
      mv -f "${_comp_file}.new" "$_comp_file"
    else
      # Keep the stale file and back off a week instead of retrying every shell.
      rm -f "${_comp_file}.new"
      [ -f "$_comp_file" ] && touch "$_comp_file"
    fi
  fi
  [ -f "$_comp_file" ] && source "$_comp_file"
done

# Tool completions, hand-placed kind: no generator, so whatever is on disk wins.
# Shell-specific file first, then the generic .sh.
_completion_static=(adkb pcpctl ollama)
for _tool in "${_completion_static[@]}"; do
  if [ -f "$HOME/.completion.${_tool}.${_sh}" ]; then
    source "$HOME/.completion.${_tool}.${_sh}"
  elif [ -f "$HOME/.completion.${_tool}.sh" ]; then
    source "$HOME/.completion.${_tool}.sh"
  fi
done

unset _sh _fzf _gcloud_path _gcloud_comp _completion_generated _completion_static _tool _comp_file
unset -f _gen_completion _completion_stale
