# vim: ft=sh
#!/bin/bash

set -u

# -----------------------------------------------------------------------------
# Overview
# Renumbers numeric tmux sessions to a dense sequence starting at 0.
# Named sessions (non‑numeric) are left untouched. This maintains a tidy
# index order for quick switching via session numbers.
# -----------------------------------------------------------------------------

# Collect numeric session names only, sort ascending
sessions=$(tmux ls -F '#S' | grep '^[0-9]\+$' | sort)

new_number=0
for number in $sessions; do
  # Rename numeric sessions in order: 0,1,2,...
  tmux rename-session -t "$number" "$new_number"
  ((new_number+=1))
done
