#!/usr/bin/env bash
# crostini-grok — idempotent lean terminal bootstrap for Chrome OS Crostini
# Safe to re-run. Stays inside the container. Never touches host partitions.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_NAME="${USER:-$(id -un)}"
HOME_DIR="${HOME:-$(getent passwd "$USER_NAME" | cut -d: -f6)}"
CONFIG_SRC="$ROOT/config"
FISH_CONF_D="$HOME_DIR/.config/fish/conf.d"
ALACRITTY_DIR="$HOME_DIR/.config/alacritty"
PROJECTS_DIR="$HOME_DIR/projects/sf"
STAMP="$(date +%Y%m%d-%H%M%S)"

log() { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }

need_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    warn "sudo not found; install packages as root or enable passwordless sudo"
    exit 1
  fi
}

install_packages() {
  need_sudo
  log "Updating apt indices"
  sudo apt-get update -y
  log "Installing lean package set"
  sudo apt-get install -y \
    fish \
    alacritty \
    fastfetch \
    git \
    iproute2 \
    util-linux \
    fonts-powerline \
    fonts-noto-color-emoji \
    fonts-dejavu-core \
    curl \
    ca-certificates
  # CHG-010 — skip Recommends (mesa-utils, lm-sensors) unused by `inxi -MC`
  sudo apt-get install -y --no-install-recommends inxi dmidecode
}

backup_fish() {
  local fish_cfg="$HOME_DIR/.config/fish"
  if [[ -d "$fish_cfg" ]] && [[ ! -L "$fish_cfg" ]]; then
    local bak="${fish_cfg}.bak.cros002.${STAMP}"
    if [[ ! -d "$bak" ]]; then
      log "Backing up fish config → $bak"
      cp -a "$fish_cfg" "$bak"
    fi
  fi
}

install_fisher_tide() {
  if ! command -v fish >/dev/null 2>&1; then
    warn "fish missing after apt install"
    exit 1
  fi

  log "Ensuring Fisher + tide + done"
  if ! fish -c 'type -q fisher' 2>/dev/null; then
    fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
  fi

  fish -c 'fisher install ilancosman/tide franciscolourenco/done' || true

  if ! fish -c 'set -q tide_left_prompt_items' 2>/dev/null; then
    log "Configuring Tide Rainbow (auto)"
    fish -c 'tide configure --auto \
      --style=Rainbow \
      --prompt_colors="16 colors" \
      --show_time="24-hour format" \
      --rainbow_prompt_separators=Angled \
      --powerline_prompt_heads=Slanted \
      --powerline_prompt_tails=Sharp \
      --powerline_prompt_style="Two lines, character and frame" \
      --prompt_connection=Dotted \
      --powerline_right_prompt_frame=Yes \
      --prompt_spacing=Compact \
      --icons="Many icons" \
      --transient=Yes'
  else
    log "Tide already configured; skipping auto configure"
  fi

  fish -c 'set -U tide_pwd_color_anchors black; set -U tide_pwd_color_dirs black; set -U tide_pwd_color_truncated_dirs black'
}

set_login_shell() {
  local current
  current="$(getent passwd "$USER_NAME" | cut -d: -f7)"
  if [[ "$current" == "/usr/bin/fish" ]]; then
    log "Login shell already fish"
    return 0
  fi
  if [[ ! -x /usr/bin/fish ]]; then
    warn "/usr/bin/fish not executable"
    exit 1
  fi
  log "Setting login shell to fish (sudo chsh)"
  sudo chsh -s /usr/bin/fish "$USER_NAME"
}

install_configs() {
  mkdir -p "$FISH_CONF_D" "$ALACRITTY_DIR" "$PROJECTS_DIR"

  if [[ -f "$CONFIG_SRC/fish/conf.d/grok.fish" ]]; then
    log "Installing grok.fish conf.d"
    install -m 644 "$CONFIG_SRC/fish/conf.d/grok.fish" "$FISH_CONF_D/grok.fish"
  fi

  if [[ -f "$CONFIG_SRC/fish/conf.d/crostini.fish" ]]; then
    log "Installing crostini.fish conf.d"
    install -m 644 "$CONFIG_SRC/fish/conf.d/crostini.fish" "$FISH_CONF_D/crostini.fish"
  fi

  mkdir -p "$HOME_DIR/.local/bin" "$HOME_DIR/.config/crostini"
  if [[ -f "$CONFIG_SRC/bin/alacritty-crostini-banner" ]]; then
    install -m 755 "$CONFIG_SRC/bin/alacritty-crostini-banner" \
      "$HOME_DIR/.local/bin/alacritty-crostini-banner"
    log "banner → $HOME_DIR/.local/bin/alacritty-crostini-banner"
  fi
  if [[ -f "$CONFIG_SRC/alacritty/host-specs.txt" ]]; then
    local host_dest="$HOME_DIR/.config/crostini/host-specs.txt"
    if [[ -f "$host_dest" ]]; then
      cp -a "$host_dest" "${host_dest}.bak.chg011.${STAMP}"
    fi
    install -m 644 "$CONFIG_SRC/alacritty/host-specs.txt" "$host_dest"
    log "host specs → $host_dest"
  fi

  if [[ -f "$CONFIG_SRC/alacritty/alacritty.toml" ]]; then
    if [[ -f "$ALACRITTY_DIR/alacritty.toml" ]]; then
      cp -a "$ALACRITTY_DIR/alacritty.toml" "$ALACRITTY_DIR/alacritty.toml.bak.chg011.${STAMP}"
    fi
    log "Installing alacritty.toml (user home expanded)"
    sed "s|__HOME__|${HOME_DIR}|g" "$CONFIG_SRC/alacritty/alacritty.toml" \
      > "$ALACRITTY_DIR/alacritty.toml"
  fi

  local bashrc="$HOME_DIR/.bashrc"
  local marker="# crostini-grok: fish handoff"
  if [[ -f "$bashrc" ]] && ! grep -qF "$marker" "$bashrc" 2>/dev/null; then
    log "Appending bash → fish handoff to ~/.bashrc"
    cat >> "$bashrc" <<'EOF'

# crostini-grok: fish handoff
# Stay in bash: CROSTINI_BASH=1 bash  (or OMARCHY_BASH_NO_FISH=1)
if [[ $- == *i* ]] && [[ -z "${CROSTINI_BASH:-}" ]] && [[ -z "${OMARCHY_BASH_NO_FISH:-}" ]]; then
  if [[ -x /usr/bin/fish ]] && [[ -z "${BASH_EXECUTION_STRING:-}" ]]; then
    exec /usr/bin/fish -l
  fi
fi
EOF
  fi
}

main() {
  log "crostini-grok bootstrap · $USER_NAME · $HOME_DIR"
  install_packages
  backup_fish
  install_fisher_tide
  set_login_shell
  install_configs
  log "Done. Run: ./scripts/verify.sh"
  log "Open Alacritty from the Chrome OS Linux apps launcher."
}

main "$@"
