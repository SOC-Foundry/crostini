#!/usr/bin/env bash
# crostini · CHG-012 — official 1password apt + Crostini wrapper + GitHub-only SSH agent
# Idempotent. Does not install Snap/Flatpak. Does not set global SSH_AUTH_SOCK.
# Does not read or copy ~/.ssh/id_ed25519.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
STAMP="$(date +%Y%m%d-%H%M%S)"
KEY_URL="https://downloads.1password.com/linux/keys/1password.asc"
KEYRING="/usr/share/keyrings/1password-archive-keyring.gpg"
LIST="/etc/apt/sources.list.d/1password.list"
DEBSIG_DIR="/etc/debsig/policies/AC2D62742012EA22"
DEBSIG_KEYDIR="/usr/share/debsig/keyrings/AC2D62742012EA22"
DEBSIG_POL_URL="https://downloads.1password.com/linux/debian/debsig/1password.pol"

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

install_repo() {
  need_sudo
  log "Adding 1Password apt repository"
  sudo mkdir -p "$(dirname "$KEYRING")"
  curl -fsSL "$KEY_URL" | sudo gpg --dearmor --yes -o "$KEYRING"
  echo "deb [arch=amd64 signed-by=${KEYRING}] https://downloads.1password.com/linux/debian/amd64 stable main" | \
    sudo tee "$LIST" >/dev/null

  sudo mkdir -p "$DEBSIG_DIR" "$DEBSIG_KEYDIR"
  curl -fsSL "$DEBSIG_POL_URL" | sudo tee "${DEBSIG_DIR}/1password.pol" >/dev/null
  curl -fsSL "$KEY_URL" | sudo gpg --dearmor --yes -o "${DEBSIG_KEYDIR}/debsig.gpg"
}

install_package() {
  need_sudo
  if dpkg -s 1password >/dev/null 2>&1; then
    log "apt package 1password already installed"
    return 0
  fi
  log "Installing 1password"
  sudo apt-get update -y
  if ! sudo apt-get install -y 1password; then
    log "fixing dependencies"
    sudo apt-get install -f -y
    sudo apt-get install -y 1password
  fi
}

install_cli() {
  need_sudo
  if dpkg -s 1password-cli >/dev/null 2>&1; then
    log "apt package 1password-cli already installed"
    return 0
  fi
  log "Installing 1password-cli (op). Not an SSH agent — item/CLI only."
  sudo apt-get install -y 1password-cli
}

install_wrapper() {
  need_sudo
  local dest=/usr/local/bin/1password-crostini
  local src="$ROOT/config/bin/1password-crostini"
  if [[ ! -f "$src" ]]; then
    warn "wrapper source missing: $src"
    exit 1
  fi
  sudo install -m 755 "$src" "$dest"
  sudo ln -sfn "$dest" /usr/local/bin/1password
  log "wrapper → $dest (PATH: /usr/local/bin/1password)"
}

install_desktop() {
  need_sudo
  local src="$ROOT/config/desktop/1password.desktop"
  local dest_sys=/usr/share/applications/1password.desktop
  local dest_user="$HOME_DIR/.local/share/applications/1password.desktop"
  if [[ ! -f "$src" ]]; then
    warn "desktop source missing: $src"
    exit 1
  fi
  if [[ -f "$dest_sys" ]]; then
    sudo cp -a "$dest_sys" "${dest_sys}.bak.chg012.${STAMP}"
    log "backed up $dest_sys → ${dest_sys}.bak.chg012.${STAMP}"
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

merge_ssh_config() {
  local src="$ROOT/config/ssh/config.1password"
  local dest="$HOME_DIR/.ssh/config"
  local marker="crostini · CHG-012"
  if [[ ! -f "$src" ]]; then
    warn "ssh config snippet missing: $src"
    exit 1
  fi
  mkdir -p "$HOME_DIR/.ssh"
  chmod 700 "$HOME_DIR/.ssh"
  if [[ -f "$dest" ]]; then
    cp -a "$dest" "${dest}.bak.chg012.${STAMP}"
    log "backed up $dest → ${dest}.bak.chg012.${STAMP}"
  fi
  if [[ -f "$dest" ]] && grep -q "$marker" "$dest"; then
    # replace existing CHG-012 block: from marker comment through next blank-line-terminated Host block
    local tmp
    tmp="$(mktemp)"
    awk -v src="$src" '
      BEGIN { skip=0 }
      /crostini · CHG-012/ { skip=1; next }
      skip && /^Host / && !/github.com/ { skip=0 }
      skip && /^$/ { next }
      skip { next }
      { print }
    ' "$dest" > "$tmp"
    {
      cat "$src"
      echo
      cat "$tmp"
    } > "$dest"
    rm -f "$tmp"
    log "replaced existing CHG-012 block in $dest"
  else
    if [[ -f "$dest" ]]; then
      local tmp
      tmp="$(mktemp)"
      { cat "$src"; echo; cat "$dest"; } > "$tmp"
      mv "$tmp" "$dest"
    else
      install -m 600 "$src" "$dest"
    fi
    log "merged GitHub-only IdentityAgent into $dest"
  fi
  chmod 600 "$dest"
}

main() {
  log "crostini · install 1Password (CHG-012)"
  check_disk
  install_repo
  install_package
  install_cli
  install_wrapper
  install_desktop
  merge_ssh_config

  if [[ -x /usr/bin/1password || -x /opt/1Password/1password ]]; then
    log "1password: $(dpkg-query -W -f '${Version}' 1password 2>/dev/null || echo present)"
  else
    warn "1password binary missing after install"
    exit 1
  fi

  log "Launch: 1password &   (X11 / no-GPU / no-sandbox)"
  log "Or Chrome OS launcher → Linux apps → 1Password"
  log "If the icon is missing: Settings → Developers → Linux → Restart"
  log "Then: Settings → Developer → Use the SSH Agent"
  log "Do not install the 1Password browser extension in Island"
  log "Do not set SSH_AUTH_SOCK globally"
  log "Import the existing GitHub key in the 1Password window (do not paste it here)"
  log "Updates: sudo apt-get update && sudo apt-get install -y 1password"
}

main "$@"
