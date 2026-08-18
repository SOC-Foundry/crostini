#!/usr/bin/env bash
# crostini · CHG-014 — Debian chromium + Crostini wrapper (personal, not Island)
# Idempotent. Does not install Google Chrome. Does not touch Island.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
STAMP="$(date +%Y%m%d-%H%M%S)"

log() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

need_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi
  command -v sudo >/dev/null 2>&1 || { warn "sudo required"; exit 1; }
}

check_disk() {
  if command -v df >/dev/null 2>&1; then
    df -h / | awk 'NR==2 {print "==> disk:", $4, "free of", $2}'
    local avail_kb
    avail_kb="$(df -Pk / | awk 'NR==2 {print $4}')"
    if [[ -n "${avail_kb:-}" && "$avail_kb" -lt 1048576 ]]; then
      warn "less than 1 GiB free on / — resize Linux disk (CHG-007) first"
      exit 1
    fi
  fi
}

install_package() {
  need_sudo
  if dpkg -s chromium >/dev/null 2>&1; then
    log "apt package chromium already installed"
    return 0
  fi
  log "Installing chromium (Debian, not Google Chrome)"
  sudo apt-get update -y
  if ! sudo apt-get install -y --no-install-recommends chromium; then
    log "fixing dependencies"
    sudo apt-get install -f -y
    sudo apt-get install -y --no-install-recommends chromium
  fi
}

install_2tab() {
  need_sudo
  local src_ext="$ROOT/config/chromium/2tab"
  local dest_ext=/usr/local/share/crostini/chromium-2tab
  local src_d="$ROOT/config/chromium/chromium.d-crostini-2tab"
  local dest_d=/etc/chromium.d/crostini-2tab
  if [[ ! -f "$src_ext/manifest.json" || ! -f "$src_ext/background.js" ]]; then
    warn "2-tab extension missing under $src_ext"
    exit 1
  fi
  if [[ ! -f "$src_d" ]]; then
    warn "chromium.d snippet missing: $src_d"
    exit 1
  fi
  sudo mkdir -p "$dest_ext" /etc/chromium.d
  sudo install -m 644 "$src_ext/manifest.json" "$dest_ext/manifest.json"
  sudo install -m 644 "$src_ext/background.js" "$dest_ext/background.js"
  if [[ -f "$dest_d" ]]; then
    sudo cp -a "$dest_d" "${dest_d}.bak.chg014.${STAMP}"
  fi
  sudo install -m 644 "$src_d" "$dest_d"
  log "2-tab cap → $dest_ext (via $dest_d)"
}

install_wrapper() {
  need_sudo
  local dest=/usr/local/bin/chromium-crostini
  local src="$ROOT/config/bin/chromium-crostini"
  if [[ ! -f "$src" ]]; then
    warn "wrapper source missing: $src"
    exit 1
  fi
  sudo install -m 755 "$src" "$dest"
  sudo ln -sfn "$dest" /usr/local/bin/chromium
  log "wrapper → $dest (PATH: /usr/local/bin/chromium)"
}

install_desktop() {
  need_sudo
  local src="$ROOT/config/desktop/chromium.desktop"
  local dest_sys=/usr/share/applications/chromium.desktop
  local dest_user="$HOME_DIR/.local/share/applications/chromium.desktop"
  if [[ ! -f "$src" ]]; then
    warn "desktop source missing: $src"
    exit 1
  fi
  if [[ -f "$dest_sys" ]]; then
    sudo cp -a "$dest_sys" "${dest_sys}.bak.chg014.${STAMP}"
    log "backed up $dest_sys → ${dest_sys}.bak.chg014.${STAMP}"
  fi
  sudo install -m 644 "$src" "$dest_sys"
  mkdir -p "$HOME_DIR/.local/share/applications"
  install -m 644 "$src" "$dest_user"
  log "desktop entry $dest_sys"
  log "desktop entry $dest_user"

  if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$dest_sys" || warn "desktop-file-validate reported issues"
  fi
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME_DIR/.local/share/applications" 2>/dev/null || true
    sudo update-desktop-database /usr/share/applications 2>/dev/null || true
  fi
}

main() {
  log "crostini · install Chromium (CHG-014)"
  check_disk
  install_package
  install_2tab
  install_wrapper
  install_desktop

  if [[ -x /usr/bin/chromium ]]; then
    log "chromium: $(dpkg-query -W -f '${Version}' chromium 2>/dev/null || echo present)"
  else
    warn "/usr/bin/chromium missing after install"
    exit 1
  fi
  log "Launch: chromium &   (X11 / no-GPU / no-sandbox / basic password store / 2 tabs)"
  log "Or Chrome OS launcher → Linux apps → Chromium"
  log "Hard cap: two tabs (most recently used). Extra tabs are closed."
  log "Personal only. Island stays Workspace / Zoom / Slack."
  log "If the icon is missing: Settings → Developers → Linux → Restart"
  log "Updates: sudo apt-get update && sudo apt-get install -y chromium"
}

main "$@"
