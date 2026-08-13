# CHG-013 · CHG-014 — Penguin: permanent Grok Build + Antigravity IDE

> Host: **`penguin`** (Chrome OS Flex · Crostini Debian 13 trixie) · Dell Latitude 7200  
> Applied: **2026-08-12** · Risk: **Low–Med**  
> Related: [penguin session summary](penguin-crostini-grok-build-session.md) · [CHG-012 Island](chg012-island-browser-penguin.md)

Two user-space chapters from the same Flex/Crostini session. Paste the README ledger blocks at the bottom when merging into the kit changelog.

| CHG | Title | Status |
|-----|--------|--------|
| **013** | Permanent Grok Build on Crostini | Applied |
| **014** | Antigravity IDE (apt + CLI + Crostini launch) | Applied |

---

# CHG-013 — Permanent Grok Build on Crostini

> `13` · **Applied** · 2026-08-12 · `penguin` · Low

## Summary

Grok Build was already installed under `~/.grok` on the **persistent** Crostini disk (`/dev/vdb`), but felt “ephemeral” because reboot workflows re-ran the curl installer and some entry points lacked `PATH`. This CHG hardens discovery and recovery so a normal Chromebook reboot does **not** require re-curling.

## Objective · Challenge · Paths

| | |
|---|---|
| **Objective** | Make `grok` reliably available after reboot without re-running `curl \| bash`; document true vs false ephemerality on Crostini. |
| **Challenge** | Installer only patches bashrc; login shell is fish (CHG-002). Some sessions start with minimal PATH. User expectation was “must re-curl every reboot,” which confuses container wipe with normal reboot. |
| **Paths** | `~/.grok/` · `~/.grok/bin/grok` · `/usr/local/bin/grok` · `/etc/profile.d/grok.sh` · `~/.config/fish/conf.d/grok.fish` · `~/.local/bin/ensure-grok` · `/usr/share/applications/grok-build.desktop` |

## What persists / what does not

| Layer | Survives Chrome OS reboot? |
|-------|----------------------------|
| Crostini rootfs + `~/.grok` (binary, auth, sessions) | **Yes** (unless Linux is removed or disk wiped) |
| apt packages, fish, Alacritty | **Yes** |
| `PATH` if only set in a one-off shell | **No** — fixed by profile hooks |
| After **Settings → Developers → Linux → Remove** | **No** — full reinstall needed |

Applied version at write-up: **grok 1.0.3** (stable).

## Execute

### 0) Confirm install already on disk (skip curl if present)

```bash
test -x "$HOME/.grok/bin/grok" && "$HOME/.grok/bin/grok" --version
# if missing:
# curl -fsSL https://x.ai/cli/install.sh | bash
```

### 1) System PATH + stable symlink

```bash
# /etc/profile.d — all login shells
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

# Always-on absolute command (works with minimal PATH)
GROK_BIN="$HOME/.grok/downloads/grok-linux-x86_64"
sudo ln -sfn "$GROK_BIN" /usr/local/bin/grok
sudo ln -sfn "$GROK_BIN" /usr/local/bin/agent
```

### 2) Fish + bash hooks

```bash
# fish (login shell after CHG-002)
mkdir -p ~/.config/fish/conf.d
cat > ~/.config/fish/conf.d/grok.fish << 'EOF'
# Grok Build CLI (persistent under ~/.grok — survives reboot on Crostini disk)
if test -d "$HOME/.grok/bin"
    fish_add_path -g "$HOME/.grok/bin"
end
EOF

# bashrc: keep official installer block if present
# >>> grok installer >>>
# export PATH="$HOME/.grok/bin:$PATH"
# [[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source ...
# <<< grok installer <<<
```

### 3) Desktop launcher + recovery helper

```bash
# Chrome OS Linux apps → "Grok Build"
sudo tee /usr/share/applications/grok-build.desktop >/dev/null << EOF
[Desktop Entry]
Type=Application
Name=Grok Build
Comment=Grok Build terminal coding agent (xAI)
Exec=alacritty -e env PATH=$HOME/.grok/bin:/usr/local/bin:/usr/bin:/bin grok
Icon=utilities-terminal
Terminal=false
Categories=Development;Utility;
StartupNotify=true
EOF

# Only re-curl if binary truly missing
mkdir -p ~/.local/bin
# ensure-grok: checks command -v / ~/.grok/bin; else runs install.sh
```

### 4) Verify

```bash
/usr/local/bin/grok --version
env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$HOME" grok --version
fish -c 'command -v grok; grok --version'
ensure-grok   # should report already installed
```

**Do not** re-run curl every reboot. Updates:

```bash
grok update
```

## Backout

```bash
sudo rm -f /usr/local/bin/grok /usr/local/bin/agent
sudo rm -f /etc/profile.d/grok.sh
sudo rm -f /usr/share/applications/grok-build.desktop
rm -f ~/.config/fish/conf.d/grok.fish
rm -f ~/.local/bin/ensure-grok
# optional full remove of product data:
# rm -rf ~/.grok
```

## Notes

- Auth: `~/.grok/auth.json` lives on the same persistent volume.
- Disk resize (10 GiB → **213 GiB** on this host) is independent; Grok itself is ~180 MiB under `~/.grok`.
- Agent tooling: avoid `pkill -f grok` patterns that match the agent wrapper command line.

---

# CHG-014 — Antigravity IDE (apt) + CLI + Crostini launch

> `14` · **Applied** · 2026-08-12 · `penguin` · Low–Med  
> Official Linux apt path: [antigravity.google/download/linux](https://antigravity.google/download/linux)

## Summary

Installed Google **Antigravity** via the **official APT repository** (package `antigravity` **1.23.2**, app reports **1.107.0**) so the user can open the IDE and **update in-app** (or `apt upgrade`). Also installed **Antigravity CLI** (`agy` **1.1.12**) from Google’s CLI installer. Crostini required an **X11 + disable-gpu + no-sandbox** wrapper so the Electron UI is visible (Wayland/DRM has no GPU nodes in the VM).

Earlier session also staged **tarball** Antigravity 2.0 hub + IDE 2.1 under `/opt` (optional; not the primary launcher after this CHG).

## Objective · Challenge · Paths

| | |
|---|---|
| **Objective** | Ship a launchable Antigravity IDE with Google’s apt auto-update path; keep CLI; make window work on Crostini. |
| **Challenge** | Official `/download/linux` apt package is the **1.x / VS Code-family** IDE, not the separate “2.0 hub” or “IDE 2.1” tarballs on the main download page. Crostini Wayland reports `drmGetDevices2` failures → GPU process exit → blank/missing window. Disk was 10 GiB mid-session (later resized to 213 GiB). |
| **Paths** | apt repo + `antigravity` package · `/usr/share/antigravity/` · `/usr/local/bin/antigravity-crostini` · `~/.local/bin/agy` · `/usr/local/bin/agy` · desktop `antigravity.desktop` |

## Products installed

| Product | Version | How | Launch |
|---------|---------|-----|--------|
| **Antigravity IDE** (primary) | pkg `1.23.2` / app `1.107.0` | `apt install antigravity` | `antigravity` · launcher **Antigravity** |
| **Antigravity CLI** | `1.1.12` | `curl …/cli/install.sh \| bash` | `agy` |
| Antigravity 2.0 hub (optional leftover) | `2.7.1` tarball | `/opt/antigravity` | not primary |
| Antigravity IDE 2.1 tarball (optional leftover) | `2.1.1` | `/opt/antigravity-ide` | prefer apt IDE |

## Execute

### 1) Antigravity CLI

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
# binary: ~/.local/bin/agy
sudo ln -sfn "$HOME/.local/bin/agy" /usr/local/bin/agy

# fish
mkdir -p ~/.config/fish/conf.d
cat > ~/.config/fish/conf.d/antigravity.fish << 'EOF'
if test -d "$HOME/.local/bin"
    fish_add_path -g "$HOME/.local/bin"
end
EOF

agy --version   # → 1.1.12
```

### 2) Official apt IDE (updatable)

From [download/linux](https://antigravity.google/download/linux):

```bash
export DEBIAN_FRONTEND=noninteractive
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
  sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

sudo apt-get update
sudo apt-get install -y antigravity

dpkg -l antigravity
/usr/share/antigravity/bin/antigravity --version
# → 1.107.0 (package 1.23.2-…)
```

### 3) Crostini launch wrapper (required for visible UI)

```bash
sudo tee /usr/local/bin/antigravity-crostini >/dev/null << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
BIN="/usr/share/antigravity/bin/antigravity"
[ -x "$BIN" ] || { echo "missing $BIN"; exit 1; }
export ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-x11}"
unset WAYLAND_DISPLAY 2>/dev/null || true
exec "$BIN" \
  --ozone-platform=x11 \
  --disable-gpu \
  --disable-gpu-compositing \
  --disable-dev-shm-usage \
  --no-sandbox \
  "$@"
EOF
sudo chmod 755 /usr/local/bin/antigravity-crostini
sudo ln -sfn /usr/local/bin/antigravity-crostini /usr/local/bin/antigravity

# Desktop entry (Chrome OS Linux apps)
sudo tee /usr/share/applications/antigravity.desktop >/dev/null << 'EOF'
[Desktop Entry]
Name=Antigravity
Comment=Experience liftoff (Google Antigravity IDE via apt; auto-update enabled)
Exec=/usr/local/bin/antigravity-crostini %F
Icon=antigravity
Type=Application
StartupNotify=true
StartupWMClass=Antigravity
Categories=TextEditor;Development;IDE;
Keywords=vscode;antigravity;ide;
EOF

# Optional: disable HW accel in user config
mkdir -p ~/.config/Antigravity
printf '%s\n' '{' '  "disable-hardware-acceleration": true' '}' > ~/.config/Antigravity/argv.json
```

### 4) Verify

```bash
command -v antigravity   # → /usr/local/bin/antigravity (wrapper)
command -v agy
antigravity &            # window should appear; then use in-app update
agy --version
```

**Updates after first run**

- In-app update UI, and/or  
- `sudo apt-get update && sudo apt-get install -y antigravity`

## Backout

```bash
# apt IDE
sudo apt-get remove --purge -y antigravity
sudo rm -f /etc/apt/sources.list.d/antigravity.list
sudo rm -f /usr/local/bin/antigravity /usr/local/bin/antigravity-crostini
sudo rm -f /usr/share/applications/antigravity.desktop

# CLI
rm -f ~/.local/bin/agy /usr/local/bin/agy
rm -f ~/.config/fish/conf.d/antigravity.fish

# optional: remove tarball experiments
# sudo rm -rf /opt/antigravity /opt/antigravity-ide
# sudo rm -f /usr/local/bin/antigravity-ide /usr/local/bin/antigravity-ide-crostini
```

## Notes · failure modes

| Symptom | Cause | Mitigation |
|---------|--------|------------|
| `agy` works, no IDE window | Wayland/GPU DRM missing in VM | Use `antigravity-crostini` flags (this CHG) |
| `apt install antigravity` is “old” | Repo currently tracks 1.x IDE line | Intended; update in-app / apt after first open |
| Confusion with 2.0 / IDE 2.1 tarballs | Different products on main download page | Prefer apt IDE as daily driver; tarballs optional |
| Large download / disk | ~160 MiB deb, ~700 MiB installed | Host resized to 213 GiB; no longer constrained |
| Desktop entry lost after `apt upgrade` | Package may overwrite `.desktop` | Re-point `Exec=` to `antigravity-crostini` or dpkg-divert |

---

## README paste blocks

### Changelog rows

| Applied | CHG | Title | Host | Status | Risk | Surfaces |
|---------|-----|-------|------|--------|------|----------|
| 2026-08-12 | [013](#chg-013--permanent-grok-build-on-crostini) | Permanent Grok Build on Crostini | penguin | Applied | Low | `~/.grok` · profile.d · fish · `/usr/local/bin/grok` |
| 2026-08-12 | [014](#chg-014--antigravity-ide-apt--cli--crostini-launch) | Antigravity IDE apt + CLI + Crostini launch | penguin | Applied | Low–Med | apt `antigravity` · `agy` · crostini wrapper |

### CHG-013 ledger body

```markdown
## CHG-013 — Permanent Grok Build on Crostini

> `13` · Applied · 2026-08-12 · `penguin` · Low  
> Detail: `docs/chg013-014-penguin-grok-permanent-and-antigravity.md`

| | |
|---|---|
| **Objective** | `grok` survives reboot without re-curl; PATH + recovery hooks. |
| **Challenge** | Fish login + minimal PATH; curl installer felt required every boot. |
| **Paths** | `~/.grok` · `/usr/local/bin/grok` · `/etc/profile.d/grok.sh` · fish conf.d · `ensure-grok` |

**Execute**

```bash
# if missing: curl -fsSL https://x.ai/cli/install.sh | bash
sudo ln -sfn "$HOME/.grok/downloads/grok-linux-x86_64" /usr/local/bin/grok
# + profile.d + fish conf.d (see detail doc)
grok --version
```

**Backout**

```bash
sudo rm -f /usr/local/bin/grok /etc/profile.d/grok.sh
rm -f ~/.config/fish/conf.d/grok.fish
```
```

### CHG-014 ledger body

```markdown
## CHG-014 — Antigravity IDE (apt) + CLI + Crostini

> `14` · Applied · 2026-08-12 · `penguin` · Low–Med  
> Detail: `docs/chg013-014-penguin-grok-permanent-and-antigravity.md`  
> Upstream: https://antigravity.google/download/linux

| | |
|---|---|
| **Objective** | Apt-install Antigravity IDE for in-app/apt updates; CLI `agy`; visible UI on Crostini. |
| **Challenge** | Apt is 1.x IDE line; Electron GPU/Wayland fails without DRM in VM. |
| **Paths** | apt `antigravity` · `/usr/share/antigravity` · `antigravity-crostini` · `agy` |

**Execute**

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
# add Google apt repo (see detail / download/linux)
sudo apt-get install -y antigravity
# install antigravity-crostini wrapper; antigravity &
```

**Backout**

```bash
sudo apt-get remove --purge -y antigravity
rm -f ~/.local/bin/agy
```
```

---

## Host end-state snapshot (2026-08-12)

| Check | Value |
|-------|--------|
| Disk | `/dev/vdb` **213 GiB** btrfs · ~207 GiB free |
| `grok` | 1.0.3 · `/usr/local/bin/grok` → `~/.grok/downloads/…` |
| `agy` | 1.1.12 |
| `antigravity` (apt) | 1.23.2 / app 1.107.0 · Crostini wrapper |
| Login shell | fish (CHG-002) |

<sub>CHG-013 · CHG-014 · penguin · 2026-08-12</sub>
