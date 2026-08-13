#!/usr/bin/env bash
# crostini-grok · CROS-009 / CHG-014 — Antigravity IDE (apt) + CLI + Crostini wrapper
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
HOME_DIR="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

install_cli() {
  if command -v agy >/dev/null 2>&1 || [[ -x "$HOME_DIR/.local/bin/agy" ]]; then
    log "agy already present"
  else
    log "Installing Antigravity CLI"
    curl -fsSL https://antigravity.google/cli/install.sh | bash
  fi
  if [[ -x "$HOME_DIR/.local/bin/agy" ]]; then
    sudo ln -sfn "$HOME_DIR/.local/bin/agy" /usr/local/bin/agy
  fi
  mkdir -p "$HOME_DIR/.config/fish/conf.d"
  if [[ -f "$ROOT/config/fish/conf.d/antigravity.fish" ]]; then
    install -m 644 "$ROOT/config/fish/conf.d/antigravity.fish" \
      "$HOME_DIR/.config/fish/conf.d/antigravity.fish"
  fi
}

install_apt_ide() {
  if dpkg -s antigravity >/dev/null 2>&1; then
    log "apt package antigravity already installed"
  else
    log "Adding Antigravity apt repository"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
      sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
      sudo tee /etc/apt/sources.list.d/antigravity.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y antigravity
  fi
}

install_wrapper() {
  local dest=/usr/local/bin/antigravity-crostini
  if [[ -f "$ROOT/config/bin/antigravity-crostini" ]]; then
    sudo install -m 755 "$ROOT/config/bin/antigravity-crostini" "$dest"
  else
    warn "wrapper source missing"
    exit 1
  fi
  sudo ln -sfn "$dest" /usr/local/bin/antigravity
  log "wrapper → /usr/local/bin/antigravity"

  if [[ -f "$ROOT/config/desktop/antigravity.desktop" ]]; then
    sudo install -m 644 "$ROOT/config/desktop/antigravity.desktop" \
      /usr/share/applications/antigravity.desktop
  fi

  mkdir -p "$HOME_DIR/.config/Antigravity"
  if [[ ! -f "$HOME_DIR/.config/Antigravity/argv.json" ]]; then
    printf '%s\n' '{' '  "disable-hardware-acceleration": true' '}' \
      > "$HOME_DIR/.config/Antigravity/argv.json"
  fi
}

main() {
  install_cli
  install_apt_ide
  install_wrapper
  if command -v agy >/dev/null 2>&1; then
    log "agy: $(agy --version 2>/dev/null || echo present)"
  fi
  if [[ -x /usr/share/antigravity/bin/antigravity ]]; then
    log "ide: $(/usr/share/antigravity/bin/antigravity --version 2>/dev/null || echo present)"
  fi
  log "Launch: antigravity &   (X11 / no-GPU / no-sandbox)"
  log "Updates: in-app, or  sudo apt-get update && sudo apt-get install -y antigravity"
}

main "$@"
