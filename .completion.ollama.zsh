# Zsh completion for Ollama CLI (v0.20+)
# https://docs.ollama.com/cli

# --- helpers ---------------------------------------------------------------

# Complete model names from `ollama list`
_ollama_models() {
  local -a models
  models=(${(f)"$(ollama list 2>/dev/null | tail -n +2 | awk '{gsub(/:/, "\\:", $1); print $1}')"})
  _describe 'model' models
}

# Complete currently running models from `ollama ps`
_ollama_running_models() {
  local -a models
  models=(${(f)"$(ollama ps 2>/dev/null | tail -n +2 | awk '{gsub(/:/, "\\:", $1); print $1}')"})
  _describe 'model' models
}

# --- subcommand completions ------------------------------------------------

_ollama_serve() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]'
}

_ollama_create() {
  local -a quantize_types=(
    'q4_0:4-bit (small, fast, lower quality)'
    'q4_1:4-bit (slightly better quality than q4_0)'
    'q5_0:5-bit (balanced size/quality)'
    'q5_1:5-bit (slightly better quality than q5_0)'
    'q8_0:8-bit (larger, near-lossless)'
    'q2_K:2-bit K-quant (smallest, lowest quality)'
    'q3_K_S:3-bit K-quant small'
    'q3_K_M:3-bit K-quant medium'
    'q3_K_L:3-bit K-quant large'
    'q4_K_S:4-bit K-quant small'
    'q4_K_M:4-bit K-quant medium (recommended)'
    'q5_K_S:5-bit K-quant small'
    'q5_K_M:5-bit K-quant medium'
    'q6_K:6-bit K-quant (high quality)'
  )
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--experimental[Enable experimental safetensors model creation]' \
    '(-f --file)'{-f,--file}'[Name of the Modelfile]:modelfile:_files' \
    '(-q --quantize)'{-q,--quantize}'[Quantize model to this level]:level:(($quantize_types))' \
    ':model name:'
}

_ollama_show() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--license[Show license of a model]' \
    '--modelfile[Show Modelfile of a model]' \
    '--parameters[Show parameters of a model]' \
    '--system[Show system message of a model]' \
    '--template[Show template of a model]' \
    '(-v --verbose)'{-v,--verbose}'[Show detailed model information]' \
    ':model:_ollama_models'
}

_ollama_run() {
  local -a think_values=(
    'true:Enable thinking'
    'false:Disable thinking'
    'high:High detail thinking (GPT-OSS)'
    'medium:Medium detail thinking (GPT-OSS)'
    'low:Low detail thinking (GPT-OSS)'
  )
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--dimensions[Truncate output embeddings to specified dimension]:dimension:' \
    '--experimental[Enable experimental agent loop with tools]' \
    '--experimental-websearch[Enable web search tool in experimental mode]' \
    '--experimental-yolo[Skip all tool approval prompts]' \
    '--format[Response format]:format:(json)' \
    '--hidethinking[Hide thinking output]' \
    '--insecure[Use an insecure registry]' \
    '--keepalive[Duration to keep a model loaded]:duration:' \
    '--nowordwrap[Do not wrap words to the next line]' \
    '--think[Enable thinking mode]:mode:(($think_values))' \
    '--truncate[Truncate inputs exceeding context length]' \
    '--verbose[Show timings for response]' \
    '--width[Image width]:width:' \
    '--height[Image height]:height:' \
    '--steps[Denoising steps]:steps:' \
    '--seed[Random seed]:seed:' \
    '--negative[Negative prompt]:prompt:' \
    ':model:_ollama_models' \
    ':prompt:'
}

_ollama_stop() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    ':model:_ollama_running_models'
}

_ollama_pull() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--insecure[Use an insecure registry]' \
    ':model:'
}

_ollama_push() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--insecure[Use an insecure registry]' \
    ':model:_ollama_models'
}

_ollama_signin() {
  _arguments '(-h --help)'{-h,--help}'[Show help]'
}

_ollama_signout() {
  _arguments '(-h --help)'{-h,--help}'[Show help]'
}

_ollama_list() {
  _arguments '(-h --help)'{-h,--help}'[Show help]'
}

_ollama_ps() {
  _arguments '(-h --help)'{-h,--help}'[Show help]'
}

_ollama_cp() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    ':source model:_ollama_models' \
    ':destination model:'
}

_ollama_rm() {
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '*:model:_ollama_models'
}

_ollama_launch() {
  local -a integrations=(
    'claude:Claude Code'
    'cline:Cline'
    'codex:Codex'
    'droid:Droid'
    'opencode:OpenCode'
    'openclaw:OpenClaw'
    'pi:Pi'
    'vscode:VS Code'
  )
  _arguments \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--config[Configure without launching]' \
    '--model[Model to use]:model:_ollama_models' \
    '(-y --yes)'{-y,--yes}'[Automatically answer yes to prompts]' \
    ':integration:(($integrations))'
}

_ollama_help() {
  local -a commands=(
    'serve' 'create' 'show' 'run' 'stop' 'pull' 'push'
    'signin' 'signout' 'list' 'ps' 'cp' 'rm' 'launch' 'help'
  )
  _arguments ':command:($commands)'
}

# --- main dispatcher -------------------------------------------------------

_ollama() {
  local -a commands=(
    'serve:Start Ollama'
    'create:Create a model'
    'show:Show information for a model'
    'run:Run a model'
    'stop:Stop a running model'
    'pull:Pull a model from a registry'
    'push:Push a model to a registry'
    'signin:Sign in to ollama.com'
    'signout:Sign out from ollama.com'
    'list:List models'
    'ps:List running models'
    'cp:Copy a model'
    'rm:Remove a model'
    'launch:Launch an integration'
    'help:Help about any command'
  )

  _arguments -C \
    '--nowordwrap[Do not wrap words to the next line]' \
    '(-v --version)'{-v,--version}'[Show version information]' \
    '--verbose[Show timings for response]' \
    '1:command:->cmd' \
    '*::arg:->args'

  case "$state" in
    cmd)
      _describe 'command' commands
      ;;
    args)
      local cmd="${words[1]}"
      # resolve aliases
      case "$cmd" in
        start) cmd=serve ;;
        ls)    cmd=list ;;
      esac
      if (( $+functions[_ollama_$cmd] )); then
        _ollama_$cmd
      fi
      ;;
  esac
}

compdef _ollama ollama
