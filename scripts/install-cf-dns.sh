#!/usr/bin/env bash
# crostini · CHG-013 — Cloudflare personal DNS (1.1.1.1 for Families, malware + adult) via DoH
# Idempotent. Official cloudflare-warp cannot run on Crostini (no ip rule).
# Does not enroll Cloudflare One / Teams. Does not change Chrome OS host DNS.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TOML_SRC="$ROOT/config/dnscrypt/dnscrypt-proxy.toml"
TOML_DST="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
RESOLV_SRC="$ROOT/config/dnscrypt/resolv.conf"
RESOLV_SHARE="/usr/local/share/crostini/dnscrypt/resolv.conf"
UNIT_SRC="$ROOT/config/systemd/crostini-cf-dns.service"
UNIT_DST="/etc/systemd/system/crostini-cf-dns.service"
HELPER_SRC="$ROOT/config/bin/cf-dns-crostini"
HELPER_DST="/usr/local/bin/cf-dns-crostini"

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
    if [[ -n "${avail_kb:-}" && "$avail_kb" -lt 262144 ]]; then
      warn "less than 256 MiB free on / — resize Linux disk (CHG-007) first"
      exit 1
    fi
  fi
}

explain_warp() {
  log "Official Cloudflare WARP (cloudflare-warp / warp-svc) is the 1.1.1.1 consumer client."
  if ip rule list >/dev/null 2>&1; then
    log "ip rule works on this kernel — WARP might start. This chapter still applies DoH (safer on Crostini)."
    return 0
  fi
  local err
  err="$(ip rule list 2>&1 || true)"
  log "Crostini guest kernel has no policy routing."
  log "  ip rule: ${err:-failed}"
  log "warp-svc hangs on RTM_GETRULE (EOPNOTSUPP) and never creates /run/cloudflare-warp/warp_service."
  log "Applied instead: dnscrypt-proxy DoH → Cloudflare Families malware+adult (family.cloudflare-dns.com)."
}

purge_warp() {
  need_sudo
  if systemctl list-unit-files warp-svc.service >/dev/null 2>&1; then
    sudo systemctl disable --now warp-svc.service 2>/dev/null || true
    sudo systemctl mask warp-svc.service 2>/dev/null || true
  fi
  sudo pkill -x warp-svc 2>/dev/null || true
  if dpkg -s cloudflare-warp >/dev/null 2>&1; then
    log "removing hung/unusable cloudflare-warp (keeps this chapter's DoH path)"
    sudo apt-get remove --purge -y cloudflare-warp
  fi
  # leftover mask if we disabled the unit before purge
  sudo rm -f /etc/systemd/system/warp-svc.service
  sudo systemctl daemon-reload 2>/dev/null || true
  if [[ -f /etc/apt/sources.list.d/cloudflare-client.list ]]; then
    sudo rm -f /etc/apt/sources.list.d/cloudflare-client.list
    log "removed Cloudflare WARP apt list"
  fi
  sudo rm -f /usr/local/bin/warp-crostini
  if ! dpkg -s cloudflare-warp >/dev/null 2>&1; then
    sudo apt-get autoremove -y --purge libnss3-tools libpcap0.8t64 >/dev/null 2>&1 || true
  fi
}

install_package() {
  need_sudo
  if dpkg -s dnscrypt-proxy >/dev/null 2>&1; then
    log "apt package dnscrypt-proxy already installed"
    return 0
  fi
  log "Installing dnscrypt-proxy (Debian, DoH)"
  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends dnscrypt-proxy ca-certificates
}

install_toml() {
  need_sudo
  if [[ ! -f "$TOML_SRC" ]]; then
    warn "toml source missing: $TOML_SRC"
    exit 1
  fi
  sudo mkdir -p /etc/dnscrypt-proxy
  if [[ -f "$TOML_DST" ]]; then
    sudo cp -a "$TOML_DST" "${TOML_DST}.bak.chg013.${STAMP}"
    log "backed up $TOML_DST → ${TOML_DST}.bak.chg013.${STAMP}"
  fi
  sudo install -m 644 "$TOML_SRC" "$TOML_DST"
  log "dnscrypt-proxy.toml → cloudflare-family (Families malware + adult)"
}

install_helper() {
  need_sudo
  if [[ ! -f "$HELPER_SRC" ]]; then
    warn "helper source missing: $HELPER_SRC"
    exit 1
  fi
  sudo install -m 755 "$HELPER_SRC" "$HELPER_DST"
  sudo mkdir -p "$(dirname "$RESOLV_SHARE")"
  sudo install -m 644 "$RESOLV_SRC" "$RESOLV_SHARE"
  log "helper → $HELPER_DST"
}

install_unit() {
  need_sudo
  if [[ ! -f "$UNIT_SRC" ]]; then
    warn "unit source missing: $UNIT_SRC"
    exit 1
  fi
  sudo install -m 644 "$UNIT_SRC" "$UNIT_DST"
  sudo systemctl daemon-reload
  sudo systemctl enable dnscrypt-proxy.socket
  sudo systemctl enable crostini-cf-dns.service
  sudo systemctl start dnscrypt-proxy.socket
  sudo systemctl restart dnscrypt-proxy.service
  log "enabled dnscrypt-proxy.socket + crostini-cf-dns.service"
}

apply_policy() {
  log "pinning penguin DNS to 127.0.2.1"
  "$HELPER_DST" on
}

main() {
  log "crostini · Cloudflare personal DNS (CHG-013)"
  check_disk
  explain_warp
  purge_warp
  install_package
  install_toml
  install_helper
  install_unit
  apply_policy

  if ! dpkg -s dnscrypt-proxy >/dev/null 2>&1; then
    warn "dnscrypt-proxy missing after install"
    exit 1
  fi
  log "dnscrypt-proxy: $(dpkg-query -W -f '${Version}' dnscrypt-proxy 2>/dev/null || echo present)"
  log "Daily: cf-dns-crostini status | on | off"
  log "Hotel portal: cf-dns-crostini off → complete portal in Chrome OS Chrome → cf-dns-crostini on"
  log "Host Chrome is not covered — Settings → Privacy and security → Use secure DNS → Cloudflare"
  log "Do not enroll a work Cloudflare One / Teams org on penguin"
}

main "$@"
