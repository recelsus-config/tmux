# vim: ft=sh
#!/usr/bin/env bash

set -euo pipefail

os=$(uname -s)

ip=""
device=""

if [ "${os}" = 'Darwin' ]; then
  # Try the interface that owns the default route first
  device=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
  if [ -n "${device:-}" ]; then
    ip=$(ipconfig getifaddr "${device}" 2>/dev/null || true)
  fi

  # If missing, try the Wi-Fi interface discovered by networksetup
  if [ -z "${ip}" ] && command -v networksetup >/dev/null 2>&1; then
    wifi_dev=$(networksetup -listallhardwareports 2>/dev/null | awk '/^(Wi-Fi|AirPort)$/ {getline; print $2; exit}')
    if [ -n "${wifi_dev:-}" ]; then
      device="${wifi_dev}"
      ip=$(ipconfig getifaddr "${device}" 2>/dev/null || true)
    fi
  fi

  # Fallback through common en* candidates
  if [ -z "${ip}" ]; then
    for cand in en0 en1 en2; do
      ip=$(ipconfig getifaddr "${cand}" 2>/dev/null || true)
      if [ -n "${ip}" ]; then
        device="${cand}"
        break
      fi
    done
  fi

  # Final fallback: scan active interfaces for an inet address
  if [ -z "${ip}" ]; then
    for cand in $(ifconfig -l 2>/dev/null); do
      ip=$(ifconfig "${cand}" inet 2>/dev/null | awk '/inet /{print $2; exit}')
      if [ -n "${ip}" ]; then
        device="${cand}"
        break
      fi
    done
  fi
elif [ "${os}" = 'Linux' ]; then
  # Choose the interface used for default route
  device=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
  # Fallback: first UP non-virtual interface
  if [ -z "${device:-}" ]; then
    device=$(ip -4 -br a 2>/dev/null | awk '$2 ~ /UP/ && $1 !~ /^(lo|docker|br-|veth|vmnet|tun|tap|tailscale|wg|zt)/ {print $1; exit}')
  fi
  if [ -n "${device:-}" ]; then
    ip=$(ip -4 -o addr show dev "${device}" scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
  fi
  # Last resort
  if [ -z "${ip}" ] && command -v hostname >/dev/null 2>&1; then
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi
fi

ip=${ip:--}
device=${device:--}
echo "${ip} [${device}]"
