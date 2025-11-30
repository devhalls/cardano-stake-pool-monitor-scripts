#!/usr/bin/env bash
set -euo pipefail

# Cycle through a simple color palette for the active pane
palette=(white yellow green cyan magenta blue red)
current="$(tmux display-message -p "#{pane_fg}" 2>/dev/null || echo "")"

next="${palette[0]}"
for ((i=0; i<${#palette[@]}; i++)); do
  if [[ "${palette[$i]}" == "$current" ]]; then
    next="${palette[$(((i+1) % ${#palette[@]}))]}"
    break
  fi
done

tmux select-pane -P "fg=$next"
