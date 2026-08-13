#!/usr/bin/env bash
# crostini-grok · CROS-008 / CHG-012 — Island browser from a local .deb
# Usage: ./scripts/install-island.sh [path-to.deb]
# Does not download Island. Stage the vendor .deb via Linux files / Share with Linux.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

log() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

DEB="${1:-}"

if [[ -z "$DEB" ]]; then
  for cand in \
    "$HOME/projects/sf/omarchy"/island-browser-stable_*_amd64.deb \
    /mnt/chromeos/MyFiles/Downloads/island-browser-stable_*_amd64.deb \
    "$HOME"/Downloads/island-browser-stable_*_amd64.deb; do
    if [[ -f "$cand" ]]; then
      DEB="$cand"
      break
    fi
  done
fi

if [[ -z "${DEB:-}" || ! -f "$DEB" ]]; then
  warn "No Island .deb found."
  warn "Drag island-browser-stable_*_amd64.deb into Linux files, or:"
  warn "  Share Downloads with Linux → /mnt/chromeos/MyFiles/Downloads/"
  warn "Then: $0 /path/to/island-browser-stable_*.deb"
  exit 1
fi

log "Installing $DEB"
if command -v df >/dev/null 2>&1; then
  df -h / | awk 'NR==2 {print "==> disk:", $4, "free of", $2}'
fi

sudo apt-get update -y
if ! sudo apt-get install -y "$DEB"; then
  log "fixing dependencies"
  sudo apt-get install -f -y
  sudo apt-get install -y "$DEB"
fi

if command -v island-browser >/dev/null 2>&1; then
  log "island-browser: $(island-browser --version 2>/dev/null || echo present)"
else
  warn "island-browser not on PATH after install"
  exit 1
fi

log "Launch: island-browser &   (or Chrome OS launcher → Island)"
log "Safe to delete the staged .deb to reclaim ~200 MiB"
