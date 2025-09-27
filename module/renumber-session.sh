# vim: ft=sh
#!/bin/bash

set -u

sessions=$(tmux ls -F '#S' | grep '^[0-9]\+$' | sort)

new_number=0
for number in $sessions; do
  # Rename numeric sessions in order: 0,1,2,...
  tmux rename-session -t "$number" "$new_number"
  ((new_number+=1))
done
