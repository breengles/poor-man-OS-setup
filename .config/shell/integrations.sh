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
    pueue)    pueue completions "$sh" ;;
    rg)       rg --generate "complete-${sh}" ;;
    uv)       uv generate-shell-completion "$sh" ;;
    *)        return 1 ;;
  esac
}

# Tool completions
# For each tool, try shell-specific file (.zsh/.bash) first, then generic (.sh).
# If no pre-generated file exists, attempt to generate and cache one.
_completion_tools=(adkb uv opencode glab pueue pcpctl delta rg)
for _tool in "${_completion_tools[@]}"; do
  if [ -f "$HOME/.completion.${_tool}.${_sh}" ]; then
    source "$HOME/.completion.${_tool}.${_sh}"
  elif [ -f "$HOME/.completion.${_tool}.sh" ]; then
    source "$HOME/.completion.${_tool}.sh"
  elif command -v "$_tool" >/dev/null 2>&1; then
    _comp_file="$HOME/.completion.${_tool}.${_sh}"
    if _gen_completion "$_tool" "$_sh" > "$_comp_file" 2>/dev/null && [ -s "$_comp_file" ]; then
      source "$_comp_file"
    else
      rm -f "$_comp_file"
    fi
  fi
done

unset _sh _fzf _gcloud_path _gcloud_comp _completion_tools _tool _comp_file
unset -f _gen_completion
