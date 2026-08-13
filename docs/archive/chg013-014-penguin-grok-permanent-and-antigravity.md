# CHG-013 · CHG-014 — Permanent Grok Build + Antigravity IDE

> Host: **penguin** · Applied 2026-08-12 · Kit: **CROS-004** + **CROS-009**

## CHG-013 — Permanent Grok Build

Grok already lived under `~/.grok` on the persistent Crostini disk, but felt ephemeral because the installer only patched bashrc and login shell is fish.

**Do not re-curl every reboot.** Updates: `grok update`.

| | |
|---|---|
| **Objective** | `grok` available after reboot without `curl \| bash`. |
| **Challenge** | Fish login + minimal PATH; curl felt required every boot. |
| **Paths** | `~/.grok` · `/usr/local/bin/grok` · `/etc/profile.d/grok.sh` · fish conf.d · `ensure-grok` |

**Execute:** `./scripts/install-grok.sh` then:

```bash
/usr/local/bin/grok --version
env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$HOME" grok --version
fish -c 'command -v grok; grok --version'
ensure-grok   # already installed
```

**Backout:**

```bash
sudo rm -f /usr/local/bin/grok /usr/local/bin/agent /etc/profile.d/grok.sh
sudo rm -f /usr/share/applications/grok-build.desktop
rm -f ~/.config/fish/conf.d/grok.fish ~/.local/bin/ensure-grok
```

Auth: `~/.grok/auth.json` is on the same volume. Avoid `pkill -f grok`.

## CHG-014 — Antigravity IDE (apt) + CLI + Crostini launch

Official apt path: https://antigravity.google/download/linux

| Product | Version (seed) | How | Launch |
|---------|----------------|-----|--------|
| Antigravity IDE | pkg 1.23.2 / app 1.107.0 | `apt install antigravity` | `antigravity` wrapper |
| Antigravity CLI | 1.1.12 | official CLI installer | `agy` |

Apt is the **1.x** VS Code-family IDE, not 2.0 hub / IDE 2.1 tarballs. Crostini has no GPU DRM — the wrapper uses X11 + `--disable-gpu` + `--no-sandbox`.

**Execute:** `./scripts/install-antigravity.sh` then `antigravity &` and `agy --version`.

Updates: in-app, or `sudo apt-get update && sudo apt-get install -y antigravity`.
If `apt upgrade` overwrites the `.desktop`, re-point `Exec=` to `/usr/local/bin/antigravity-crostini`.

**Backout:**

```bash
sudo apt-get remove --purge -y antigravity
sudo rm -f /usr/local/bin/antigravity /usr/local/bin/antigravity-crostini
rm -f ~/.local/bin/agy /usr/local/bin/agy ~/.config/fish/conf.d/antigravity.fish
```

## Seed host snapshot (2026-08-12)

| Check | Value |
|-------|--------|
| Disk | `/dev/vdb` **213 GiB** btrfs · ~207 GiB free |
| `grok` | 1.0.3 · `/usr/local/bin/grok` |
| `agy` | 1.1.12 |
| `antigravity` | 1.23.2 / 1.107.0 · Crostini wrapper |
| Login shell | fish |
