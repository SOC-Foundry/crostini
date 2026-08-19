#!/usr/bin/env bash
# crostini · CHG-015 — Debian btop + Alacritty Linux-apps launcher
# Idempotent. Does not replace htop. Does not install lm-sensors.
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
  if dpkg -s btop >/dev/null 2>&1; then
    log "apt package btop already installed"
    return 0
  fi
  log "Installing btop (Debian)"
  sudo apt-get update -y
  if ! sudo apt-get install -y --no-install-recommends btop; then
    log "fixing dependencies"
    sudo apt-get install -f -y
    sudo apt-get install -y --no-install-recommends btop
  fi
}

install_wrapper() {
  need_sudo
  local dest=/usr/local/bin/btop-crostini
  local src="$ROOT/config/bin/btop-crostini"
  if [[ ! -f "$src" ]]; then
    warn "wrapper source missing: $src"
    exit 1
  fi
  sudo install -m 755 "$src" "$dest"
  log "wrapper → $dest"
}

install_config() {
  local src="$ROOT/config/btop/btop.conf"
  local dest_dir="$HOME_DIR/.config/btop"
  local dest="$dest_dir/btop.conf"
  if [[ ! -f "$src" ]]; then
    warn "btop.conf source missing: $src"
    exit 1
  fi
  mkdir -p "$dest_dir"
  if [[ -f "$dest" ]]; then
    cp -a "$dest" "${dest}.bak.chg015.${STAMP}"
    log "backed up $dest → ${dest}.bak.chg015.${STAMP}"
  fi
  install -m 644 "$src" "$dest"
  log "config → $dest"
}

install_desktop() {
  need_sudo
  local src="$ROOT/config/desktop/btop.desktop"
  local dest_sys=/usr/share/applications/btop.desktop
  local dest_user="$HOME_DIR/.local/share/applications/btop.desktop"
  if [[ ! -f "$src" ]]; then
    warn "desktop source missing: $src"
    exit 1
  fi
  if [[ -f "$dest_sys" ]]; then
    sudo cp -a "$dest_sys" "${dest_sys}.bak.chg015.${STAMP}"
    log "backed up $dest_sys → ${dest_sys}.bak.chg015.${STAMP}"
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
  log "crostini · install btop (CHG-015)"
  check_disk
  install_package
  install_wrapper
  install_config
  install_desktop

  if [[ -x /usr/bin/btop ]]; then
    log "btop: $(/usr/bin/btop --version 2>/dev/null | head -1 || dpkg-query -W -f '${Version}' btop 2>/dev/null || echo present)"
  else
    warn "/usr/bin/btop missing after install"
    exit 1
  fi
  log "In-terminal: btop"
  log "Linux apps:  btop  (Alacritty, not Chrome OS Terminal)"
  log "CPU / RAM / disk / net are the guest. Host battery: crosh battery_test 1"
  log "If the icon is missing: Settings → Developers → Linux → Restart"
  log "Updates: sudo apt-get update && sudo apt-get install -y btop"
}

main "$@"
