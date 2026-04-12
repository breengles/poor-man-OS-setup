#!/usr/bin/env bash
# Claude Code status line: model name + context/rate limit progress bars

input=$(cat)

eval "$(echo "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
model = data.get('model', {}).get('display_name', 'Claude')
used = data.get('context_window', {}).get('used_percentage')
rl = data.get('rate_limits', {})
rate_5h = (rl.get('five_hour') or {}).get('used_percentage')
rate_7d = (rl.get('seven_day') or {}).get('used_percentage')
print(f'model={model!r}')
print(f'used={used!r}')
print(f'rate_5h={rate_5h!r}')
print(f'rate_7d={rate_7d!r}')
")"

# Color a value: green <50%, yellow 50-79%, red >=80%
color_for() {
  local pct=$1
  if [ "$pct" -ge 80 ]; then
    echo "\033[31m"   # red
  elif [ "$pct" -ge 50 ]; then
    echo "\033[33m"   # yellow
  else
    echo "\033[32m"   # green
  fi
}

# Build a progress bar of given width
make_bar() {
  local pct=$1 width=$2
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local bar=""
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  for i in $(seq 1 $empty);  do bar="${bar}░"; done
  echo "$bar"
}

reset="\033[0m"
output="$model"

# Context window bar (10 chars wide)
if [ -n "$used" ] && [ "$used" != "None" ]; then
  ctx_int=$(printf "%.0f" "$used")
  ctx_color=$(color_for "$ctx_int")
  ctx_bar=$(make_bar "$ctx_int" 10)
  output=$(printf "%s  ctx %b%s%b %d%%" "$output" "$ctx_color" "$ctx_bar" "$reset" "$ctx_int")
fi

# 5-hour rate limit bar (10 chars wide)
if [ -n "$rate_5h" ] && [ "$rate_5h" != "None" ]; then
  r5_int=$(printf "%.0f" "$rate_5h")
  r5_color=$(color_for "$r5_int")
  r5_bar=$(make_bar "$r5_int" 10)
  output=$(printf "%s  5h %b%s%b %d%%" "$output" "$r5_color" "$r5_bar" "$reset" "$r5_int")
fi

# 7-day rate limit bar (10 chars wide)
if [ -n "$rate_7d" ] && [ "$rate_7d" != "None" ]; then
  r7_int=$(printf "%.0f" "$rate_7d")
  r7_color=$(color_for "$r7_int")
  r7_bar=$(make_bar "$r7_int" 10)
  output=$(printf "%s  7d %b%s%b %d%%" "$output" "$r7_color" "$r7_bar" "$reset" "$r7_int")
fi

printf "%s" "$output"
