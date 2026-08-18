#!/usr/bin/env bash
# crostini · CHG-013 — official WARP client cannot run on Crostini (no ip rule).
# Applies the same personal DNS goal: Cloudflare 1.1.1.1 for Families via DoH.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$ROOT/install-cf-dns.sh" "$@"
