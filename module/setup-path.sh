# vim: ft=sh
#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Overview
# Determine and prepend appropriate brew/bin paths without clobbering PATH.
# Handles: macOS (Intel/ARM) and Linuxbrew on Linux.
# Then: if outside tmux, attach to "newest" session by name (numeric > string),
#       otherwise create a new session. Update tmux PATH only when server exists.
# -----------------------------------------------------------------------------

current_path=${PATH:-}
os=$(uname -s)

prepend_path_component() {
  # Adds a component to PATH if not already present
  local component="$1"
  if [ -n "${component}" ] && [ -d "${component}" ]; then
    case ":${current_path}:" in
      *":${component}:"*) : ;; # already present
      *) current_path="${component}:${current_path}" ;;
    esac
  fi
}

brew_bin=""

if [ "${os}" = "Darwin" ]; then
  # Prefer Homebrew if installed; detect arch-specific default locations first
  if [ -x /opt/homebrew/bin/brew ]; then
    brew_bin=/opt/homebrew/bin
  elif [ -x /usr/local/bin/brew ]; then
    brew_bin=/usr/local/bin
  elif command -v brew >/dev/null 2>&1; then
    # Fallback to discovered brew
    brew_bin=$(dirname "$(command -v brew)")
  fi
elif [ "${os}" = "Linux" ]; then
  # Linuxbrew common default
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    brew_bin=/home/linuxbrew/.linuxbrew/bin
  elif command -v brew >/dev/null 2>&1; then
    brew_bin=$(dirname "$(command -v brew)")
  fi
fi

# -----------------------------------------------------------------------------
# Prepend brew paths if found (bin and sbin)
# -----------------------------------------------------------------------------
if [ -n "${brew_bin}" ]; then
  prepend_path_component "${brew_bin}"
  # In case brew prefix provides sbin separately
  brew_sbin=${brew_bin%/bin}/sbin
  prepend_path_component "${brew_sbin}"
fi

# -----------------------------------------------------------------------------
# Ensure standard system paths are present (idempotent)
# -----------------------------------------------------------------------------
prepend_path_component "/usr/local/sbin"
prepend_path_component "/usr/local/bin"
prepend_path_component "/usr/sbin"
prepend_path_component "/usr/bin"
prepend_path_component "/sbin"
prepend_path_component "/bin"

# -----------------------------------------------------------------------------
# If tmux server already exists, export the computed PATH into tmux global env.
# NOTE: Do NOT start tmux server just for this.
# -----------------------------------------------------------------------------
if tmux list-sessions >/dev/null 2>&1; then
  tmux set-environment -g PATH "${current_path}"
fi

# -----------------------------------------------------------------------------
# Session control (outside tmux only):
# - if sessions exist: attach to the "newest" by name
#   * numeric-only names: choose max numeric (10 > 9)
#   * otherwise: choose max lexicographic (z > a)
# - if no sessions: create new session
# -----------------------------------------------------------------------------
if [ -z "${TMUX-}" ]; then
  if tmux list-sessions >/dev/null 2>&1; then
    target_session=$(
      tmux list-sessions -F '#S' |
        awk '
          /^[0-9]+$/ { nums[++n]=$0; next }
          { strs[++s]=$0 }
          END {
            if (n > 0) {
              max=nums[1]
              for (i=2;i<=n;i++) if (nums[i]+0 > max+0) max=nums[i]
              print max
            } else {
              max=strs[1]
              for (i=2;i<=s;i++) if (strs[i] > max) max=strs[i]
              print max
            }
          }
        '
    )
    exec tmux attach -t "${target_session}"
  else
    exec tmux new
  fi
fi

exit 0

