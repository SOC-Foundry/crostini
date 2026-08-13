#!/usr/bin/env bash
# crostini-grok · CROS-004 / CHG-013 — permanent Grok Build on Crostini
# Idempotent. Does not re-curl if ~/.grok/bin/grok already exists.
set -euo pipefail

HOME_DIR="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
GROK_HOME_BIN="$HOME_DIR/.grok/bin/grok"
GROK_DOWNLOAD="${GROK_DOWNLOAD:-$HOME_DIR/.grok/downloads/grok-linux-x86_64}"
FISH_CONF_D="$HOME_DIR/.config/fish/conf.d"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

need_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi
  command -v sudo >/dev/null 2>&1 || { warn "sudo required"; exit 1; }
}

resolve_binary() {
  if [[ -x "$GROK_HOME_BIN" ]]; then
    printf '%s\n' "$GROK_HOME_BIN"
    return 0
  fi
  if [[ -x "$GROK_DOWNLOAD" ]]; then
    printf '%s\n' "$GROK_DOWNLOAD"
    return 0
  fi
  if command -v grok >/dev/null 2>&1; then
    command -v grok
    return 0
  fi
  return 1
}

maybe_install_product() {
  if resolve_binary >/dev/null; then
    return 0
  fi
  log "Grok binary missing — running official installer once"
  curl -fsSL https://x.ai/cli/install.sh | bash
}

install_profile_d() {
  need_sudo
  log "Writing /etc/profile.d/grok.sh"
  sudo tee /etc/profile.d/grok.sh >/dev/null << 'EOF'
# Grok Build CLI — persistent under $HOME/.grok
if [ -d "$HOME/.grok/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.grok/bin:"*) ;;
    *) PATH="$HOME/.grok/bin:$PATH" ;;
  esac
  export PATH
fi
EOF
  sudo chmod 644 /etc/profile.d/grok.sh
}

install_symlinks() {
  need_sudo
  local target
  if [[ -x "$GROK_DOWNLOAD" ]]; then
    target="$GROK_DOWNLOAD"
  elif [[ -x "$GROK_HOME_BIN" ]]; then
    target="$GROK_HOME_BIN"
  else
    warn "no grok binary to symlink"
    return 1
  fi
  log "Symlinking /usr/local/bin/grok → $target"
  sudo ln -sfn "$target" /usr/local/bin/grok
  sudo ln -sfn "$target" /usr/local/bin/agent
}

install_fish_hook() {
  mkdir -p "$FISH_CONF_D"
  if [[ -f "$ROOT/config/fish/conf.d/grok.fish" ]]; then
    install -m 644 "$ROOT/config/fish/conf.d/grok.fish" "$FISH_CONF_D/grok.fish"
  else
    cat > "$FISH_CONF_D/grok.fish" <<'EOF'
# Grok Build CLI (persistent under ~/.grok — survives reboot on Crostini disk)
if test -d "$HOME/.grok/bin"
    fish_add_path -g "$HOME/.grok/bin"
end
EOF
  fi
  log "fish conf.d/grok.fish ready"
}

install_ensure_helper() {
  mkdir -p "$HOME_DIR/.local/bin"
  if [[ -f "$ROOT/scripts/ensure-grok" ]]; then
    install -m 755 "$ROOT/scripts/ensure-grok" "$HOME_DIR/.local/bin/ensure-grok"
  fi
}

install_desktop() {
  need_sudo
  local src="$ROOT/config/desktop/grok-build.desktop"
  if [[ -f "$src" ]]; then
    sudo install -m 644 "$src" /usr/share/applications/grok-build.desktop
    log "desktop entry grok-build.desktop"
  fi
}

main() {
  maybe_install_product
  install_profile_d
  install_symlinks
  install_fish_hook
  install_ensure_helper
  install_desktop

  if [[ -x /usr/local/bin/grok ]]; then
    log "grok: $(/usr/local/bin/grok --version 2>/dev/null || echo present)"
  fi
  log "Done. Updates: grok update  (do not re-curl every reboot)"
}

main "$@"
