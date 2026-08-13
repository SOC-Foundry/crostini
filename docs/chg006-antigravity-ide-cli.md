# CHG-006 — Antigravity IDE · CLI

> Applied · 2026-08-12 · `penguin` · Low–Med  
> README: [CHG-006](../README.md#chg-006--antigravity-ide--cli) · Script: `scripts/install-antigravity.sh`  
> Upstream: https://antigravity.google/download/linux

## Objective

Google **Antigravity** IDE via **apt** (in-app / apt updates) plus **CLI** (`agy`), with a **Crostini-safe** launcher so the UI is visible.

## Challenge

- Apt package is the IDE line (`antigravity`), not tarball marketing names.  
- Electron Wayland/DRM fails in the VM (`drmGetDevices2`) → blank window.  
- Wrapper: X11 · `--disable-gpu` · `--no-sandbox`.

## Paths

- apt `antigravity` → `/usr/share/antigravity/`  
- `~/.local/bin/agy` · `/usr/local/bin/agy`  
- `config/bin/antigravity-crostini` → `/usr/local/bin/antigravity`  
- desktop entry

## Execute

```bash
./scripts/install-antigravity.sh
agy --version
antigravity &
```

Seed: package **1.23.2** / app **1.107.0** · CLI **1.1.12**.

Optional leftovers on seed (not primary): `/opt/antigravity` · `/opt/antigravity-ide` tarballs.

## Verify

```bash
dpkg -l antigravity
command -v antigravity agy
# window appears under Chrome OS (not blank)
```

## Backout

```bash
sudo apt-get remove --purge -y antigravity
sudo rm -f /usr/local/bin/antigravity /usr/local/bin/antigravity-crostini
rm -f ~/.local/bin/agy /usr/local/bin/agy
rm -f ~/.config/fish/conf.d/antigravity.fish
```
