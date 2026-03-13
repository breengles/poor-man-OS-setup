#!/usr/bin/env bash
# Claude Code status line: model name + context usage progress bar

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -z "$used" ]; then
  printf "%s" "$model"
  exit 0
fi

# Round to integer
used_int=$(printf "%.0f" "$used")

# Build a 20-char progress bar
bar_width=20
filled=$(( used_int * bar_width / 100 ))
empty=$(( bar_width - filled ))

bar=""
for i in $(seq 1 $filled); do bar="${bar}█"; done
for i in $(seq 1 $empty);  do bar="${bar}░"; done

# Color the bar: green <50%, yellow 50-79%, red >=80%
if [ "$used_int" -ge 80 ]; then
  color="\033[31m"   # red
elif [ "$used_int" -ge 50 ]; then
  color="\033[33m"   # yellow
else
  color="\033[32m"   # green
fi
reset="\033[0m"

printf "%s  %b%s%b %d%%" "$model" "$color" "$bar" "$reset" "$used_int"
