#!/usr/bin/env bash
# crostini-grok — one-shot environment checks
set -euo pipefail

PASS=0
FAIL=0
WARN=0

ok() { printf '[ok]   %s\n' "$*"; PASS=$((PASS + 1)); }
bad() { printf '[fail] %s\n' "$*"; FAIL=$((FAIL + 1)); }
soft() { printf '[warn] %s\n' "$*"; WARN=$((WARN + 1)); }

USER_NAME="${USER:-$(id -un)}"
SHELL_PATH="$(getent passwd "$USER_NAME" | cut -d: -f7 || true)"

if [[ "$SHELL_PATH" == "/usr/bin/fish" ]]; then
  ok "login shell is fish"
else
  bad "login shell is '${SHELL_PATH:-unknown}' (want /usr/bin/fish)"
fi

if command -v fish >/dev/null 2>&1; then
  ok "fish: $(fish --version 2>&1 | head -1)"
else
  bad "fish not on PATH"
fi

if command -v alacritty >/dev/null 2>&1; then
  ok "alacritty present"
else
  bad "alacritty missing"
fi

if [[ -f "${HOME}/.config/alacritty/alacritty.toml" ]]; then
  ok "alacritty.toml present"
else
  soft "alacritty.toml missing under ~/.config/alacritty"
fi

if [[ -x "${HOME}/.local/bin/alacritty-crostini-banner" ]]; then
  ok "alacritty-crostini-banner present"
else
  soft "alacritty banner script missing (CHG-011)"
fi

if command -v fastfetch >/dev/null 2>&1; then
  ok "fastfetch present"
else
  soft "fastfetch missing"
fi

if command -v inxi >/dev/null 2>&1; then
  ok "inxi: $(inxi --version 2>/dev/null | head -1 || echo present)"
else
  soft "inxi missing (CHG-010: apt install --no-install-recommends inxi dmidecode; then: inxi -MC)"
fi

if command -v git >/dev/null 2>&1; then
  ok "git: $(git --version)"
else
  soft "git missing"
fi

if command -v fish >/dev/null 2>&1; then
  if fish -c 'type -q fisher' 2>/dev/null; then
    ok "fisher available"
    fish -c 'fisher list' 2>/dev/null | sed 's/^/       /' || true
  else
    soft "fisher not installed in fish"
  fi
fi

if [[ -d "${HOME}/.grok/bin" ]]; then
  ok "~/.grok/bin exists"
else
  soft "~/.grok/bin missing (run install-grok / official installer)"
fi

if [[ -x /usr/local/bin/grok ]]; then
  ok "/usr/local/bin/grok → $(readlink -f /usr/local/bin/grok 2>/dev/null || echo symlink)"
elif command -v grok >/dev/null 2>&1 || [[ -x "${HOME}/.grok/bin/grok" ]]; then
  GBIN="$(command -v grok 2>/dev/null || echo "${HOME}/.grok/bin/grok")"
  ok "grok resolves: $GBIN"
else
  soft "grok not on PATH (run ./scripts/install-grok.sh)"
fi

if command -v grok >/dev/null 2>&1 || [[ -x /usr/local/bin/grok ]]; then
  GBIN="$(command -v grok 2>/dev/null || echo /usr/local/bin/grok)"
  "$GBIN" --version 2>/dev/null | sed 's/^/       /' || true
fi

if [[ -f /etc/profile.d/grok.sh ]]; then
  ok "/etc/profile.d/grok.sh present"
else
  soft "profile.d/grok.sh missing (CROS-004)"
fi

if [[ -f "${HOME}/.config/fish/conf.d/grok.fish" ]]; then
  ok "fish conf.d/grok.fish present"
else
  soft "fish conf.d/grok.fish missing"
fi

if command -v agy >/dev/null 2>&1 || [[ -x "${HOME}/.local/bin/agy" ]]; then
  ABIN="$(command -v agy 2>/dev/null || echo "${HOME}/.local/bin/agy")"
  ok "agy: $($ABIN --version 2>/dev/null || echo present)"
else
  soft "agy missing (optional CROS-009)"
fi

if [[ -x /usr/local/bin/antigravity-crostini ]] || command -v antigravity >/dev/null 2>&1; then
  ok "antigravity launcher present"
else
  soft "antigravity missing (optional CROS-009)"
fi

if command -v island-browser >/dev/null 2>&1; then
  ok "island-browser: $(island-browser --version 2>/dev/null || echo present)"
else
  soft "island-browser missing (optional CROS-008)"
fi

if dpkg -s spotify-client >/dev/null 2>&1 && [[ -x /usr/local/bin/spotify-crostini ]]; then
  ok "spotify: $(dpkg-query -W -f '${Version}' spotify-client 2>/dev/null || echo present) (crostini wrapper)"
elif command -v spotify >/dev/null 2>&1; then
  soft "spotify on PATH but wrapper missing (run ./scripts/install-spotify.sh)"
else
  soft "spotify-client missing (optional CHG-009)"
fi

if [[ -f /usr/share/applications/spotify.desktop ]]; then
  ok "spotify.desktop present"
else
  soft "spotify.desktop missing from /usr/share/applications"
fi

if dpkg -s 1password >/dev/null 2>&1 && [[ -x /usr/local/bin/1password-crostini ]]; then
  ok "1password: $(dpkg-query -W -f '${Version}' 1password 2>/dev/null || echo present) (crostini wrapper)"
elif command -v 1password >/dev/null 2>&1; then
  soft "1password on PATH but wrapper missing (run ./scripts/install-1password.sh)"
else
  soft "1password missing (optional CHG-012)"
fi

if [[ -S "${HOME}/.1password/agent.sock" ]]; then
  ok "1password SSH agent socket present"
else
  soft "1password agent socket missing (launch app → Settings → Developer → Use the SSH Agent)"
fi

if ssh -G github.com 2>/dev/null | grep -qi 'identityagent ~/.1password/agent.sock\|identityagent /home/.*/.1password/agent.sock'; then
  ok "ssh IdentityAgent for github.com is 1password"
else
  soft "ssh -G github.com is not using ~/.1password/agent.sock"
fi

if [[ -e "${HOME}/.ssh/id_ed25519" ]]; then
  soft "~/.ssh/id_ed25519 still on disk — import into 1Password then shred (CHG-012)"
else
  ok "no ~/.ssh/id_ed25519 on disk"
fi

case "${SSH_AUTH_SOCK:-}" in
  *1password*)
    soft "SSH_AUTH_SOCK points at 1Password globally (${SSH_AUTH_SOCK}) — CHG-012 wants host-scoped IdentityAgent only"
    ;;
esac

if grep -q '^audio.play_bitrate_enumeration=4' "${HOME}"/.config/spotify/Users/*/prefs 2>/dev/null; then
  ok "spotify bitrate Very High (4)"
elif [[ -d "${HOME}/.config/spotify/Users" ]]; then
  soft "spotify user prefs exist but Very High not pinned (re-run install-spotify.sh)"
fi

if dpkg -s chromium >/dev/null 2>&1 && [[ -x /usr/local/bin/chromium-crostini ]]; then
  ok "chromium: $(dpkg-query -W -f '${Version}' chromium 2>/dev/null || echo present) (crostini wrapper)"
elif command -v chromium >/dev/null 2>&1; then
  soft "chromium on PATH but wrapper missing (run ./scripts/install-chromium.sh)"
else
  soft "chromium missing (optional CHG-014)"
fi

if [[ -f /usr/share/applications/chromium.desktop ]] && grep -q chromium-crostini /usr/share/applications/chromium.desktop; then
  ok "chromium.desktop uses crostini wrapper"
elif [[ -f /usr/share/applications/chromium.desktop ]]; then
  soft "chromium.desktop present but not the CHG-014 wrapper"
fi

if [[ -f /usr/local/share/crostini/chromium-2tab/manifest.json ]] && grep -q load-extension /etc/chromium.d/crostini-2tab 2>/dev/null; then
  ok "chromium 2-tab cap extension installed"
elif dpkg -s chromium >/dev/null 2>&1; then
  soft "chromium 2-tab cap missing (re-run ./scripts/install-chromium.sh)"
fi

if dpkg -s dnscrypt-proxy >/dev/null 2>&1 && [[ -x /usr/local/bin/cf-dns-crostini ]]; then
  ok "dnscrypt-proxy: $(dpkg-query -W -f '${Version}' dnscrypt-proxy 2>/dev/null || echo present) (cf-dns-crostini)"
elif command -v dnscrypt-proxy >/dev/null 2>&1 || dpkg -s dnscrypt-proxy >/dev/null 2>&1; then
  soft "dnscrypt-proxy installed but helper missing (run ./scripts/install-cf-dns.sh)"
else
  soft "dnscrypt-proxy missing (optional CHG-013)"
fi

if [[ -f /etc/resolv.conf ]] && grep -q 'nameserver 127.0.2.1' /etc/resolv.conf && [[ ! -L /etc/resolv.conf ]]; then
  ok "resolv.conf pinned to 127.0.2.1 (Cloudflare DoH stub)"
elif [[ -f /etc/resolv.conf ]] && grep -q 'nameserver 127.0.2.1' /etc/resolv.conf; then
  soft "resolv.conf has 127.0.2.1 but is still a symlink — run cf-dns-crostini on"
else
  soft "resolv.conf is not the CHG-013 stub (hotel off, or CHG-013 not applied)"
fi

if grep -q "cloudflare-family" /etc/dnscrypt-proxy/dnscrypt-proxy.toml 2>/dev/null; then
  ok "dnscrypt-proxy server_names include cloudflare-family"
elif grep -q "cloudflare-security" /etc/dnscrypt-proxy/dnscrypt-proxy.toml 2>/dev/null; then
  soft "dnscrypt-proxy still on cloudflare-security — want cloudflare-family (1.1.1.3)"
fi

if ss -lun 2>/dev/null | grep -q '127.0.2.1:53'; then
  ok "dnscrypt-proxy listening on 127.0.2.1:53"
elif dpkg -s dnscrypt-proxy >/dev/null 2>&1; then
  soft "dnscrypt-proxy installed but 127.0.2.1:53 is not listening"
fi

if [[ -f /usr/local/share/ca-certificates/cloudflare-gateway.crt ]]; then
  if openssl x509 -in /usr/local/share/ca-certificates/cloudflare-gateway.crt -noout -checkend 0 >/dev/null 2>&1; then
    ok "Cloudflare Gateway CA present in system trust (CHG-013 optional)"
  else
    soft "Cloudflare Gateway CA on disk is expired — do not use the 2025-02-02 public PEM"
  fi
  if command -v certutil >/dev/null 2>&1 && certutil -d "sql:${HOME}/.pki/nssdb" -L 2>/dev/null | grep -qi 'Cloudflare Gateway'; then
    ok "NSS ~/.pki/nssdb has Cloudflare Gateway"
  else
    soft "Gateway CA in system store but not in ~/.pki/nssdb (run ./scripts/install-cf-ca.sh)"
  fi
else
  soft "Cloudflare Gateway CA not installed (optional CHG-013)"
fi

if command -v df >/dev/null 2>&1; then
  FREE="$(df -h / 2>/dev/null | awk 'NR==2 {print $4" free of "$2}')"
  ok "disk: ${FREE:-unknown}"
fi

printf '\nSummary: %s ok · %s warn · %s fail\n' "$PASS" "$WARN" "$FAIL"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
