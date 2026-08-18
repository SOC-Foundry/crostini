#!/usr/bin/env bash
# crostini · CHG-013 (optional) — Cloudflare Gateway CA → Debian trust + NSS
# Does not enroll Zero Trust. Does not start WARP. Refuses expired PEMs.
# Usage: ./scripts/install-cf-ca.sh /path/to/certificate.pem
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST_CRT="/usr/local/share/ca-certificates/cloudflare-gateway.crt"
DEST_PEM="/usr/local/share/ca-certificates/cloudflare-gateway.pem"
NICK="Cloudflare Gateway"
TRUST="CT,C,C"

log() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
install-cf-ca.sh — trust a Cloudflare Gateway / WARP inspection CA

  ./scripts/install-cf-ca.sh /path/to/certificate.pem

Download a *current* cert from Zero Trust → Traffic settings → Certificates
(Download .pem). The public developers.cloudflare.com/Cloudflare_CA.pem
expired 2025-02-02 and is refused.

Does not enroll Cloudflare One / Teams. Does not start warp-svc (still blocked
on this guest — see CHG-013). Consumer 1.1.1.1 WARP does not need this CA.

Host Chrome OS Chrome is a separate store (Settings → certificates). Not this
script.
EOF
}

need_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi
  command -v sudo >/dev/null 2>&1 || { warn "sudo required"; exit 1; }
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

require_pem() {
  local src="${1:-}"
  if [[ -z "$src" || "$src" == "-h" || "$src" == "--help" ]]; then
    usage
    exit 2
  fi
  if [[ ! -f "$src" ]]; then
    warn "certificate not found: $src"
    warn "Drag the .pem into Linux files, or: Share with Linux from Chrome OS Files."
    exit 1
  fi
  if ! openssl x509 -in "$src" -noout >/dev/null 2>&1; then
    warn "not a readable PEM/X.509 certificate: $src"
    exit 1
  fi
  if ! openssl x509 -in "$src" -noout -checkend 0 >/dev/null 2>&1; then
    warn "certificate is expired — refused"
    openssl x509 -in "$src" -noout -subject -dates >&2
    warn "Default Cloudflare_CA.pem died 2025-02-02. Get a new one from the Zero Trust dashboard."
    exit 1
  fi
  printf '%s' "$src"
}

install_tools() {
  need_sudo
  if dpkg -s libnss3-tools >/dev/null 2>&1 && command -v update-ca-certificates >/dev/null 2>&1; then
    return 0
  fi
  log "Installing ca-certificates + libnss3-tools (certutil)"
  as_root apt-get update -y
  as_root apt-get install -y --no-install-recommends ca-certificates libnss3-tools openssl
}

install_system_store() {
  local src="$1"
  need_sudo
  as_root mkdir -p /usr/local/share/ca-certificates
  if [[ -f "$DEST_CRT" ]]; then
    as_root cp -a "$DEST_CRT" "${DEST_CRT}.bak.chg013.${STAMP}"
    log "backed up $DEST_CRT"
  fi
  # Debian update-ca-certificates only picks up *.crt
  as_root install -m 644 "$src" "$DEST_CRT"
  as_root ln -sfn "$(basename "$DEST_CRT")" "$DEST_PEM"
  as_root update-ca-certificates
  log "system trust: $DEST_CRT → update-ca-certificates"
}

nss_dbs() {
  printf '%s\n' \
    "${HOME_DIR}/.pki/nssdb" \
    "${HOME_DIR}/.local/share/pki/nssdb"
}

ensure_nssdb() {
  local db="$1"
  mkdir -p "$db"
  chmod 700 "$db"
  if [[ ! -f "$db/cert9.db" ]]; then
    certutil -d "sql:${db}" -N --empty-password
    log "created NSS db $db"
  fi
}

install_nss() {
  local src="$1" db
  if ! command -v certutil >/dev/null 2>&1; then
    warn "certutil missing after install"
    exit 1
  fi
  for db in $(nss_dbs); do
    if [[ -d "$db" || "$db" == "${HOME_DIR}/.pki/nssdb" ]]; then
      if [[ -d "$db" ]]; then
        cp -a "$db" "${db}.bak.chg013.${STAMP}"
        log "backed up $db"
      fi
      ensure_nssdb "$db"
      # replace same nickname if present
      certutil -d "sql:${db}" -D -n "$NICK" >/dev/null 2>&1 || true
      certutil -d "sql:${db}" -A -t "$TRUST" -n "$NICK" -i "$src"
      log "NSS $db ← $NICK ($TRUST)"
    fi
  done
}

show_info() {
  local src="$1"
  echo "--- certificate ---"
  openssl x509 -in "$src" -noout -subject -issuer -dates
  openssl x509 -in "$src" -noout -fingerprint -sha256
}

verify() {
  echo "--- system store ---"
  if [[ -f "$DEST_CRT" ]]; then
    openssl x509 -in "$DEST_CRT" -noout -subject -dates
  else
    echo "(missing $DEST_CRT)"
  fi
  echo
  echo "--- NSS nicknames ---"
  local db
  for db in $(nss_dbs); do
    echo "# $db"
    if [[ -f "$db/cert9.db" ]]; then
      certutil -d "sql:${db}" -L 2>/dev/null | grep -i -E 'Cloudflare|Gateway' || certutil -d "sql:${db}" -L 2>/dev/null | tail -5
    else
      echo "(no cert9.db)"
    fi
  done
  echo
  log "Restart Island / Chromium so they reload NSS."
  log "Host Chrome OS Chrome is unchanged."
}

main() {
  log "crostini · Cloudflare Gateway CA (CHG-013 optional)"
  local src
  src="$(require_pem "${1:-}")"
  show_info "$src"
  install_tools
  install_system_store "$src"
  install_nss "$src"
  verify
}

main "$@"
