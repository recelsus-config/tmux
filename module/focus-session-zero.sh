# vim: ft=sh
#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Overview
# Keeps the current tmux session only and renames it to "0".
# All other sessions are closed. Handles conflicts with an existing "0" session.
# Safe to run multiple times; ignores transient races due to hooks.
# -----------------------------------------------------------------------------

if [ -z "${TMUX:-}" ]; then
  echo "This command must be run inside tmux" >&2
  exit 1
fi

current_session=$(tmux display-message -p '#S')

# Kill all sessions except the current one
while IFS= read -r session_name; do
  if [ "${session_name}" != "${current_session}" ]; then
    # Ignore failures in case sessions disappear due to hooks
    tmux kill-session -t "${session_name}" >/dev/null 2>&1 || true
  fi
done < <(tmux list-sessions -F '#S')

# If another session named "0" exists, remove it to avoid rename conflict
if [ "${current_session}" != "0" ] && tmux has-session -t 0 2>/dev/null; then
  tmux kill-session -t 0 >/dev/null 2>&1 || true
fi

# Rename the current session to 0 if needed
if [ "${current_session}" != "0" ]; then
  tmux rename-session -t "${current_session}" 0
fi

tmux display-message "Kept current session only; named it 0"

exit 0

