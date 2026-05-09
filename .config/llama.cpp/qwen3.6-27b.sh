#!/usr/bin/env bash
# Launch Qwen3.6-27B Q4_K_M via llama-server on port 8080.
#
# Memory budget on 36 GB M3 Pro:
#   model (Q4_K_M)         ~16 GB
#   KV cache (q4_0, 128K)   ~8 GB
#   leaving ~12 GB for OS + activations.
#
# Trade-off: q4_0 KV cache costs some quality vs q8_0 but is the only way to fit
# 128K context here. Drop -c to 65536 and switch to -ctk q8_0 -ctv q8_0 if you'd
# rather have a higher-quality KV cache at half the context.

set -euo pipefail

MODEL="${MODEL:-$HOME/models/qwen3.6-27b/Qwen3.6-27B-Q4_K_M.gguf}"
PORT="${PORT:-8080}"
CTX="${CTX:-131072}"

exec llama-server \
  --model "$MODEL" \
  --alias qwen3.6-27b \
  --host 127.0.0.1 \
  --port "$PORT" \
  --ctx-size "$CTX" \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  --flash-attn \
  --jinja \
  --n-gpu-layers 999 \
  --metrics \
  "$@"
