# vim: ft=sh
#!/usr/bin/env bash

set -euo pipefail

# Determine and prepend appropriate brew/bin paths without clobbering PATH
# Handles: macOS (Intel/ARM), Linuxbrew on Linux. No-op if brew not found.

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

# Prepend brew bin if found
if [ -n "${brew_bin}" ]; then
  prepend_path_component "${brew_bin}"
  # In case brew prefix provides sbin separately
  brew_sbin=${brew_bin%/bin}/sbin
  prepend_path_component "${brew_sbin}"
fi

# Always ensure standard system paths are available (idempotent)
prepend_path_component "/usr/local/sbin"
prepend_path_component "/usr/local/bin"
prepend_path_component "/usr/sbin"
prepend_path_component "/usr/bin"
prepend_path_component "/sbin"
prepend_path_component "/bin"

# Set into tmux environment for all clients
tmux set-environment -g PATH "${current_path}"

exit 0

