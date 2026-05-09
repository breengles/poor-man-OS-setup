#!/usr/bin/env bash
# Launch Qwen3.6-35B-A3B (MoE, ~3B active) UD-Q4_K_M via llama-server on port 8080.
#
# Memory budget on 36 GB M3 Pro:
#   model (UD-Q4_K_M)     ~22 GB
#   KV cache (q8_0, 64K)   ~8 GB
#   leaving ~6 GB for OS + activations -- tight, watch memory pressure.
#
# Drop CTX to 32768 if macOS starts swapping.

set -euo pipefail

MODEL="${MODEL:-$HOME/models/qwen3.6-35b-a3b/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf}"
PORT="${PORT:-8080}"
CTX="${CTX:-65536}"

exec llama-server \
  --model "$MODEL" \
  --alias qwen3.6-35b-a3b \
  --host 127.0.0.1 \
  --port "$PORT" \
  --ctx-size "$CTX" \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --flash-attn \
  --jinja \
  --n-gpu-layers 999 \
  --metrics \
  --sleep-idle-seconds 600 \
  "$@"
