#!/usr/bin/env bash
# crostini · CHG-009 — official spotify-client + Crostini wrapper
# Idempotent. Does not replace the guest Pulse/PipeWire stack.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
STAMP="$(date +%Y%m%d-%H%M%S)"
KEY_URL="https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc"
KEYRING="/etc/apt/keyrings/spotify.gpg"
LIST="/etc/apt/sources.list.d/spotify.list"

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
  log "Adding Spotify apt repository"
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL "$KEY_URL" | sudo gpg --dearmor --yes -o "$KEYRING"
  echo "deb [signed-by=${KEYRING}] https://repository.spotify.com stable non-free" | \
    sudo tee "$LIST" >/dev/null
}

install_package() {
  need_sudo
  if dpkg -s spotify-client >/dev/null 2>&1; then
    log "apt package spotify-client already installed"
    return 0
  fi
  log "Installing spotify-client"
  sudo apt-get update -y
  if ! sudo apt-get install -y spotify-client; then
    log "fixing dependencies"
    sudo apt-get install -f -y
    sudo apt-get install -y spotify-client
  fi
}

install_wrapper() {
  need_sudo
  local dest=/usr/local/bin/spotify-crostini
  local src="$ROOT/config/bin/spotify-crostini"
  if [[ ! -f "$src" ]]; then
    warn "wrapper source missing: $src"
    exit 1
  fi
  sudo install -m 755 "$src" "$dest"
  sudo ln -sfn "$dest" /usr/local/bin/spotify
  log "wrapper → $dest (PATH: /usr/local/bin/spotify)"
}

install_desktop() {
  need_sudo
  local src="$ROOT/config/desktop/spotify.desktop"
  local dest_sys=/usr/share/applications/spotify.desktop
  local dest_user="$HOME_DIR/.local/share/applications/spotify.desktop"
  if [[ ! -f "$src" ]]; then
    warn "desktop source missing: $src"
    exit 1
  fi
  if [[ -f "$dest_sys" ]]; then
    sudo cp -a "$dest_sys" "${dest_sys}.bak.chg009.${STAMP}"
    log "backed up $dest_sys → ${dest_sys}.bak.chg009.${STAMP}"
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

upsert_pref() {
  local file="$1" key="$2" val="$3"
  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$file"
  else
    printf '%s=%s\n' "$key" "$val" >> "$file"
  fi
}

pin_quality() {
  local dir="$HOME_DIR/.config/spotify/Users"
  local f found=0
  if [[ ! -d "$dir" ]]; then
    warn "no Spotify user prefs yet — sign in once, then re-run $0 to pin Very High"
    return 0
  fi
  shopt -s nullglob
  for f in "$dir"/*/prefs; do
    found=1
    cp -a "$f" "${f}.bak.chg009.${STAMP}"
    upsert_pref "$f" "audio.play_bitrate_non_metered_migrated" "true"
    upsert_pref "$f" "audio.sync_bitrate_enumeration" "4"
    upsert_pref "$f" "audio.play_bitrate_enumeration" "4"
    upsert_pref "$f" "audio.play_bitrate_non_metered_enumeration" "4"
    log "pinned Very High bitrate in user prefs"
  done
  shopt -u nullglob
  if [[ "$found" -eq 0 ]]; then
    warn "no Users/*/prefs yet — sign in once, then re-run $0 to pin Very High"
  fi
}

probe_audio() {
  if ! command -v pactl >/dev/null 2>&1; then
    warn "pactl missing — cannot probe Pulse (pipewire-pulse is already on the seed host)"
    return 0
  fi
  if ! pactl info >/dev/null 2>&1; then
    warn "pactl info failed — guest Pulse socket down; do not reinstall PipeWire; restart Linux from Chrome OS Settings"
    return 0
  fi
  local sink
  sink="$(pactl get-default-sink 2>/dev/null || true)"
  if [[ -z "$sink" || "$sink" == *auto_null* ]]; then
    warn "no usable Pulse sink (${sink:-empty}) — check Chrome OS volume; do not apt-install pipewire-audio"
    return 0
  fi
  log "pulse sink: $sink"
}

main() {
  log "crostini · install Spotify (CHG-009)"
  check_disk
  install_repo
  install_package
  install_wrapper
  install_desktop
  pin_quality
  probe_audio

  if [[ -x /usr/bin/spotify ]]; then
    log "spotify-client: $(dpkg-query -W -f '${Version}' spotify-client 2>/dev/null || echo present)"
  else
    warn "/usr/bin/spotify missing after install"
    exit 1
  fi
  log "Launch: spotify &   (X11 / no-GPU / no-sandbox / Pulse)"
  log "Or Chrome OS launcher → Linux apps → Spotify"
  log "If the icon is missing: Settings → Developers → Linux → Restart"
  log "Updates: sudo apt-get update && sudo apt-get install -y spotify-client"
}

main "$@"
