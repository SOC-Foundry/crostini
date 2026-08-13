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

if command -v fastfetch >/dev/null 2>&1; then
  ok "fastfetch present"
else
  soft "fastfetch missing"
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

if command -v df >/dev/null 2>&1; then
  FREE="$(df -h / 2>/dev/null | awk 'NR==2 {print $4" free of "$2}')"
  ok "disk: ${FREE:-unknown}"
fi

printf '\nSummary: %s ok · %s warn · %s fail\n' "$PASS" "$WARN" "$FAIL"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
