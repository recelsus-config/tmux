#!/bin/bash

set -eu

script_name=$(basename "$0")

# No tmux server / no sessions -> nothing to do
if ! tmux list-sessions >/dev/null 2>&1; then
  exit 0
fi

new_number=0

tmux list-sessions -F '#{session_id} #{session_name}' \
  | awk '$2 ~ /^[0-9]+$/ { print $1, $2 }' \
  | sort -k2,2n \
  | while read -r session_id session_name; do
      new_name="$new_number"

      if [ "$session_name" != "$new_name" ]; then
        tmux rename-session -t "$session_id" "$new_name"
      fi

      new_number=$((new_number + 1))
    done
