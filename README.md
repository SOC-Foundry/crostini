# crostini

**A real Linux desktop inside Chrome OS.**

Take a retired enterprise laptop. Put **Chrome OS Flex** on it. Turn on Linux. Rebuild the muscle memory you already have, in order:

**shell → terminal → browser → chat → music → IDE → git**

Not a toy terminal. Not a cloud IDE. A **Debian Crostini VM** (`penguin`) that you treat as the computer. The host stays thin. The VM is where you live.

Scripts in this repo are shortcuts. Every chapter below has the full commands and config — you can rebuild the desktop without opening a script.

```
Chrome OS Flex  →  Crostini (penguin)  →  fish · Alacritty · browser · chat · Spotify · IDE · git
     thin host           Debian VM              operator desktop (user-space only)
```

Chrome OS **Linux apps** is the Start menu. A `.desktop` file on disk is what puts an icon there.

---

## Contents

| | |
|---|---|
| [1 · Thesis](#1--thesis) | Why this exists |
| [2 · Chrome OS Flex](#2--chrome-os-flex) | Old PCs → developer workstations |
| [3 · Enable Linux (Crostini)](#3--enable-linux-crostini) | Turn the VM on |
| [4 · Seed hardware](#4--seed-hardware) | Latitude 7200 reference |
| [5 · Quickstart](#5--quickstart) | Bootstrap the kit |
| [6 · Chapters](#6--chapters-chg-ledger) | Change log as narrative |
| [7 · Layout](#7--repository-layout) | Scripts & config |
| [8 · Non-goals](#8--non-goals) | What we refuse to own |
| [9 · Changelog](#9--changelog) | Full chronological ledger |

---

## 1 · Thesis

Chromebooks (and Flex machines) are often dismissed as kiosk OS. That is incomplete. **Crostini** is a real Linux container: `apt`, a systemd user session, Wayland/X via sommelier, a disk that survives reboot, and a Chrome OS launcher that surfaces Linux `.desktop` entries.

If you already ship on Arch, you are not learning a new OS. You are remapping the same ownership table onto Debian inside a VM:

| You already do | You do here |
|----------------|-------------|
| Own the shell | **fish** + Tide |
| Own the terminal | **Alacritty** |
| Own the browser | **Island** (work) · **Chromium** (personal Linux, CHG-014) |
| Own chat | **WasIstLos** (WhatsApp Web shell) |
| Own music | **Spotify** (apt + Crostini wrapper) |
| Own the IDE | **Antigravity** (apt + Crostini GPU flags) |
| Own git auth | **SSH ed25519** to personal GitHub (1Password agent, CHG-012) |
| Own DNS on public Wi‑Fi | **Cloudflare 1.1.1.1 for Families** (DoH, CHG-013) |
| Own guest load | **btop** (CHG-015) |
| Own agents | Optional **Grok Build** (permanent install) |

Work stays in the VM: `~/.config/**`, `~/.local/**`, `/usr/local/bin`, apt. No dual-boot. No LUKS on the Chrome OS disk. Crosh is not the workstation.

This repository is the **runbook** for that proof — not a distro, not a Grok marketing page. Agents (CHG-005) are optional infrastructure. The desktop is the point.

---

## 2 · Chrome OS Flex

### Not a Chromebook — a PC running Chrome OS

The seed machine for this kit is a **Dell Latitude 7200**, not a retail Chromebook. It runs **[Chrome OS Flex](https://chromeos.google/products/chromeos-flex/)**: Google’s installer that puts Chrome OS on ordinary x86 hardware.

That distinction matters:

| | Native Chromebook | Chrome OS Flex |
|--|-------------------|----------------|
| Hardware | Google-certified boards | Your existing laptop/desktop |
| Firmware | Chrome OS verified boot | Typically UEFI + Flex image |
| Linux (Crostini) | Yes (most devices) | Yes (when supported on the device) |
| Typical use | Managed education / fleet | **Breathe life into old fleet iron** |

The 7200 is already a keyboard, a screen, and enough CPU. Flex keeps Windows off the metal. You do not buy a second laptop to stay productive.

### Why Flex is a developer lever

Enterprise laptops from 2018–2021 often still have:

- 8–16 GiB RAM  
- NVMe or decent SATA SSD  
- dual-core / quad-core Intel that is *fine* for terminal + browser + one IDE  
- a screen and keyboard you already own  

Windows 11 and full Linux desktops on that iron can feel heavy (updates, drivers, GPU, AV). Flex is the opposite posture:

1. **Host OS is thin** — browser, windowing, power management, verified updates.  
2. **Linux is a VM you control** — resize disk, install Debian packages, break and rebuild the container without reinstalling the host.  
3. **Minimal hardware bar** — if the machine can run Flex and enable Linux, you can run this kit.  

The seed host is that proof, docked or undocked. The same idea works on any PC that can run Flex and enable Linux.

### Install Flex (high level)

1. Create the Flex USB installer from Google’s Flex documentation.  
2. Boot the target PC from USB (UEFI).  
3. Install Flex to internal storage (wipes the drive — back up first).  
4. Sign in, update Chrome OS, then enable Linux (next section).  

Certified and community hardware lists live on Google’s Flex site; enterprise Dells of the 7000 series are common successes.

---

## 3 · Enable Linux (Crostini)

Works on **Chrome OS** and **Chrome OS Flex** when the device supports Linux development environment.

1. Open **Settings**.  
2. Search for **Linux** or open **About ChromeOS → Developers**.  
3. Find **Linux development environment** → **Turn on**.  
4. Accept disk size defaults for first boot, or set larger if you already know you want browsers/IDEs (seed host later used **213 GiB**).  
5. Wait for the container to provision. Hostname is typically **`penguin`**.  
6. Open the **Terminal** app once; complete any first-run prompts.  

You now have Debian in a VM. Confirm:

```bash
hostname          # penguin
cat /etc/os-release | head -3
df -h /
```

After the first Linux `.desktop` file lands, Chrome OS grows a **Linux apps** folder in the launcher. That folder is how you open Alacritty, Island, Spotify, Antigravity. If an icon is missing after install, the desktop file is usually on disk and garcon is stale — **Settings → Developers → Linux → Restart**.

### Files from Chrome OS → Linux

Chrome OS **My files** is not mounted into penguin by default.

- Drag files into **Linux files** in the Files app, or  
- Right-click a folder → **Share with Linux**.  

Needed for local `.deb` installs (e.g. Island).

### Resize the Linux disk later

**Settings → Developers → Linux development environment → Disk size.**  
Btrfs on the seed host expanded live from **10 GiB → 213 GiB** without reinstall.

---

## 4 · Seed hardware

**Host** (Chrome OS / operator — not visible as DMI inside the VM):

| | |
|---|---|
| Machine | Dell Latitude 7200 |
| Host OS | Chrome OS Flex |
| Container | `penguin` · Debian 13 (trixie) · x86_64 |
| Disk (final) | `/dev/vdb` · **213 GiB** btrfs |
| Kernel | Chrome OS guest kernel (`*-cros*`) |

**Guest** (`inxi -MCzm`, CHG-010):

| | |
|---|---|
| Machine (`-M`) | System **ChromiumOS** · product **crosvm** · BIOS crosvm |
| CPU (`-C`) | **Intel Core i7-8665U** · 8× 1-core SMP (virtual topology) |
| RAM (`-m`) | **16 GiB** est. · **14.07 GiB** available to penguin |

**Spec commands**

```bash
# VM (penguin) — machine + CPU + RAM
inxi -MCzm
```

```text
# Host (Chrome OS) — crosh, Ctrl+Alt+T. There is no inxi on Flex.
battery_test 1
storage_status
```

Also: **Settings → About ChromeOS → Additional details**, or `chrome://system`. Do not install `lshw` expecting a Latitude dump.

Enough for shell + Alacritty + Island + Spotify + Antigravity + agents. Resize early if you plan Electron / CEF apps.

---

## 5 · Quickstart

Clone the kit inside penguin, bootstrap the shell and terminal, then add the apps you actually want. Fish first, then Alacritty (lands in `~/projects/sf`), then optional browser / music / IDE / agent.

### Script path

```bash
# inside penguin Terminal (or Alacritty after CHG-002)
sudo apt-get update
sudo apt-get install -y git

git clone git@github.com:SOC-Foundry/crostini.git ~/projects/sf/crostini
# or HTTPS if SSH is not set up yet:
# git clone https://github.com/SOC-Foundry/crostini.git ~/projects/sf/crostini

cd ~/projects/sf/crostini
chmod +x scripts/*
./scripts/bootstrap.sh          # fish · Tide · Alacritty · inxi · land ~/projects/sf
./scripts/install-grok.sh       # optional agent CLI — skip if you do not want it
./scripts/verify.sh
```

Optional:

```bash
./scripts/install-island.sh /path/to/island-browser-stable_*.deb
./scripts/install-antigravity.sh
./scripts/install-spotify.sh
./scripts/install-1password.sh
./scripts/install-cf-dns.sh      # personal Cloudflare DNS (hotel / public Wi‑Fi)
./scripts/install-chromium.sh    # personal Linux Chromium (not Island)
./scripts/install-btop.sh        # guest resource TUI (Alacritty)
./scripts/install-cf-ca.sh /path/to/certificate.pem   # optional Gateway CA + NSS
```

### What those scripts do

| Script | Lands |
|--------|--------|
| `bootstrap.sh` | apt (incl. `inxi`), fisher + Tide + done, `chsh` to fish, Alacritty banner + `~/projects/sf`, bash→fish handoff |
| `install-island.sh` | local Island `.deb` via apt |
| `install-spotify.sh` | Spotify apt repo + wrapper + `.desktop` |
| `install-1password.sh` | 1Password apt repo + wrapper + GitHub-only SSH agent |
| `install-cf-dns.sh` | Cloudflare Families malware + adult DoH (`dnscrypt-proxy`, 1.1.1.3). Official WARP cannot run on Crostini. |
| `install-chromium.sh` | Debian Chromium + Crostini wrapper (personal, not Island) |
| `install-btop.sh` | Debian btop + Alacritty Linux-apps launcher (guest CPU/RAM/disk/net) |
| `install-cf-ca.sh` | CHG-013 optional: Gateway CA → Debian trust + NSS (current PEM only) |
| `install-antigravity.sh` | Antigravity apt repo + CLI + wrapper |
| `install-grok.sh` | Grok binary (curl once) + PATH hooks |
| `verify.sh` | one-shot checks (optional apps warn, do not fail) |

Then open **Alacritty**, **Chromium**, **Island**, **Spotify**, **Antigravity**, **btop**, or **WasIstLos** from the Chrome OS **Linux apps** folder.

Manual commands for every step are in [§6](#6--chapters-chg-ledger). You do not need the scripts.

---

## 6 · Chapters (CHG ledger)

Chapters are numbered in **apply order** on the seed host. First the machine is typeable (001–002). Then Linux apps: browser, chat, music (003, 004, 009). The editor uses the same Crostini GPU wrapper as Spotify (006). Disk is why those stacks fit (007). Git is how this repo got here (008). Personal GitHub private key leaves disk via 1Password SSH agent (012). Hotel / public Wi‑Fi DNS is Cloudflare Families over DoH (013); official WARP cannot start on this guest. Personal Linux browser is Debian Chromium (014). Live guest load is btop (015). Agents are optional (005). Hardware is guest `inxi` plus host crosh (010); the Alacritty banner prints both and lands in `~/projects/sf` (011).

| CHG | Title | Applied | Risk |
|-----|--------|---------|------|
| [001](#chg-001--fish--tide--done) | Fish · Tide · done | 2026-08-12 | Low |
| [002](#chg-002--alacritty-startup) | Alacritty startup banner | 2026-08-12 | Low |
| [003](#chg-003--island-browser) | Island browser | 2026-08-12 | Low–Med |
| [004](#chg-004--wasistlos-whatsapp) | WasIstLos (WhatsApp) | 2026-08-12 | Low |
| [005](#chg-005--agent-cli-permanent-install) | Agent CLI permanent install (Grok Build) | 2026-08-12 | Low |
| [006](#chg-006--antigravity-ide--cli) | Antigravity IDE + CLI | 2026-08-12 | Low–Med |
| [007](#chg-007--disk-resize) | Disk resize 10 → 213 GiB | 2026-08-12 | Low |
| [008](#chg-008--git-ssh-on-fish) | Git SSH on fish | 2026-08-13 | Low |
| [009](#chg-009--spotify-desktop) | Spotify desktop | 2026-08-14 | Low–Med |
| [010](#chg-010--inxi-hardware-probe) | inxi hardware probe | 2026-08-14 | Low |
| [011](#chg-011--alacritty-banner--projectssf) | Alacritty banner + `~/projects/sf` | 2026-08-14 | Low |
| [012](#chg-012--1password-personal-github-ssh-agent) | 1Password · personal GitHub SSH agent | 2026-08-15 | Med |
| [013](#chg-013--cloudflare-personal-dns) | Cloudflare personal DNS (Families DoH) | 2026-08-18 | Med |
| [014](#chg-014--debian-chromium) | Debian Chromium (personal, 2 tabs) | 2026-08-18 | Low–Med |
| [015](#chg-015--btop) | btop (guest resource TUI) | 2026-08-18 | Low |

Longer write-ups: [`docs/chg00N-*.md`](docs/). Scripts: [`scripts/`](scripts/).

---

### CHG-001 — Fish · Tide · done

> Applied · 2026-08-12 · Low

**Why this step.** You cannot think in bash snippets on this machine — login shell has to be the one you already type.

**Surfaces.** `~/.config/fish/` · login shell · `~/.bashrc` · fisher plugins · packages `fish`, `fonts-powerline`, `fonts-noto-color-emoji`.

**Script.** `./scripts/bootstrap.sh` (also CHG-002, 010 packages, 011 banner).

**Manual.**

```bash
sudo apt-get update -y
sudo apt-get install -y \
  fish alacritty fastfetch git iproute2 util-linux \
  fonts-powerline fonts-noto-color-emoji fonts-dejavu-core \
  curl ca-certificates

# Fisher + Tide + done
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
fish -c 'fisher install ilancosman/tide franciscolourenco/done'
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
fish -c 'set -U tide_pwd_color_anchors black; set -U tide_pwd_color_dirs black; set -U tide_pwd_color_truncated_dirs black'

sudo chsh -s /usr/bin/fish "$USER"

mkdir -p ~/.config/fish/conf.d
install -m 644 config/fish/conf.d/crostini.fish ~/.config/fish/conf.d/crostini.fish
# optional if you want the agent later:
# install -m 644 config/fish/conf.d/grok.fish ~/.config/fish/conf.d/grok.fish
```

**Config** — append to `~/.bashrc` so interactive bash hands off (stay in bash with `CROSTINI_BASH=1 bash`):

```bash
# crostini-grok: fish handoff
if [[ $- == *i* ]] && [[ -z "${CROSTINI_BASH:-}" ]] && [[ -z "${OMARCHY_BASH_NO_FISH:-}" ]]; then
  if [[ -x /usr/bin/fish ]] && [[ -z "${BASH_EXECUTION_STRING:-}" ]]; then
    exec /usr/bin/fish -l
  fi
fi
```

Backup live fish config first: `cp -a ~/.config/fish ~/.config/fish.bak.chg001.$(date +%Y%m%d-%H%M%S)`.

**Verify.**

```bash
getent passwd "$USER" | cut -d: -f7   # /usr/bin/fish
fish -c 'fisher list'                 # fisher · tide · done
```

**Backout.**

```bash
sudo chsh -s /bin/bash "$USER"
# restore ~/.config/fish.bak.chg001.* if you took one
```

---

### CHG-002 — Alacritty startup

> Applied · 2026-08-12 · Low

**Why this step.** Chrome OS has no Super+Return. The Linux terminal dumps a one-shot snapshot, then fish. **CHG-011** is the current banner and landing path (`~/projects/sf`).

**Surfaces.** `~/.config/alacritty/alacritty.toml` · packages `alacritty`, `fastfetch`.

**Script.** `./scripts/bootstrap.sh`.

**Manual.**

```bash
sudo apt-get install -y alacritty fastfetch
mkdir -p ~/.config/alacritty ~/.local/bin ~/projects/sf
install -m 755 config/bin/alacritty-crostini-banner ~/.local/bin/alacritty-crostini-banner
sed "s|__HOME__|${HOME}|g" config/alacritty/alacritty.toml \
  > ~/.config/alacritty/alacritty.toml
```

**Config** — current startup (full file: `config/alacritty/alacritty.toml`):

```toml
[terminal]
osc52 = "CopyPaste"

[terminal.shell]
program = "__HOME__/.local/bin/alacritty-crostini-banner"
```

The banner script prints `uname` · `ip` · `lsblk -f` · VM `inxi -MCzm` · host specs · `fastfetch`, then `cd ~/projects/sf` and `exec fish -l`.

**Verify.** Open **Alacritty** from Linux apps. Banner, then Tide prompt in `~/projects/sf`.

```bash
alacritty --version
ls /usr/share/applications/Alacritty.desktop
```

**Backout.** Restore or remove `~/.config/alacritty/alacritty.toml`. Optional: `sudo apt-get remove --purge -y alacritty`.

---

### CHG-003 — Island browser

> Applied · 2026-08-12 · Low–Med

**Why this step.** Some SSO and work sites need a real Chromium inside the VM, not the Chrome OS browser.

**Surfaces.** staged `island-browser-stable_*_amd64.deb` · package `island-browser-stable` · `/usr/bin/island-browser`.

**Script.** `./scripts/install-island.sh /path/to/island-browser-stable_*_amd64.deb`

**Manual.**

```bash
# drag the vendor .deb into Linux files, or Share Downloads with Linux
sudo apt-get update -y
sudo apt-get install -y /path/to/island-browser-stable_*_amd64.deb
# if depends fail:
sudo apt-get install -f -y
sudo apt-get install -y /path/to/island-browser-stable_*_amd64.deb
island-browser &
```

Do not commit the `.deb`. Safe to delete after install (~200 MiB staged). Seed: **151.1.97.29**. No extra GPU flags on the seed Flex host.

**Verify.**

```bash
island-browser --version
# launcher: Island
```

**Backout.**

```bash
sudo apt-get remove --purge -y island-browser-stable
sudo apt-get autoremove -y
```

---

### CHG-004 — WasIstLos (WhatsApp)

> Applied · 2026-08-12 · Low

**Why this step.** Chat is part of the desktop. Debian ships an unofficial WhatsApp Web shell; there is no official Meta Linux client.

**Surfaces.** package `wasistlos` · binary `wasistlos` · desktop **WasIstLos**.

**Script.** none — apt only.

**Manual.**

```bash
sudo apt-get update -y
sudo apt-get install -y wasistlos
wasistlos &
# phone: WhatsApp → Linked devices → Link a device → scan QR
```

Seed: **wasistlos 1.7.0-2**. Prefer after disk headroom (CHG-007).

**Verify.** Launcher shows **WasIstLos**; QR link succeeds with phone online.

**Backout.**

```bash
sudo apt-get remove --purge -y wasistlos
sudo apt-get autoremove -y
```

---

### CHG-005 — Agent CLI permanent install

> Applied · 2026-08-12 · Low

**Why this step.** Optional. Agents are infrastructure, not the thesis. If you want Grok Build, it must survive reboot without re-curl.

**Surfaces.** `~/.grok/` · `/usr/local/bin/grok` · `/etc/profile.d/grok.sh` · `~/.config/fish/conf.d/grok.fish` · `ensure-grok`.

**Script.** `./scripts/install-grok.sh` then `ensure-grok`.

**Manual.**

```bash
# official installer only if ~/.grok/bin/grok is missing
curl -fsSL https://x.ai/cli/install.sh | bash

sudo ln -sfn "$HOME/.grok/bin/grok" /usr/local/bin/grok
sudo tee /etc/profile.d/grok.sh >/dev/null << 'EOF'
if [ -d "$HOME/.grok/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.grok/bin:"*) ;;
    *) PATH="$HOME/.grok/bin:$PATH" ;;
  esac
  export PATH
fi
EOF
sudo chmod 644 /etc/profile.d/grok.sh

mkdir -p ~/.config/fish/conf.d
install -m 644 config/fish/conf.d/grok.fish ~/.config/fish/conf.d/grok.fish
install -m 755 scripts/ensure-grok ~/.local/bin/ensure-grok
sudo install -m 644 config/desktop/grok-build.desktop /usr/share/applications/grok-build.desktop

grok --version
# later: grok update
```

**Config** — `config/fish/conf.d/grok.fish`:

```fish
if test -d "$HOME/.grok/bin"
    fish_add_path -g "$HOME/.grok/bin"
end
```

**Verify.**

```bash
command -v grok
env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$HOME" grok --version
```

**Backout.**

```bash
sudo rm -f /usr/local/bin/grok /usr/local/bin/agent
sudo rm -f /etc/profile.d/grok.sh /usr/share/applications/grok-build.desktop
rm -f ~/.config/fish/conf.d/grok.fish ~/.local/bin/ensure-grok
# optional: rm -rf ~/.grok
```

---

### CHG-006 — Antigravity IDE · CLI

> Applied · 2026-08-12 · Low–Med

**Why this step.** The editor has to be a window you can see. Electron on Crostini dies on Wayland/DRM without a wrapper.

**Surfaces.** apt `antigravity` · `/usr/share/antigravity/` · `agy` · `/usr/local/bin/antigravity-crostini` · desktop entry.

**Script.** `./scripts/install-antigravity.sh`

**Manual.**

```bash
# CLI
curl -fsSL https://antigravity.google/cli/install.sh | bash
sudo ln -sfn "$HOME/.local/bin/agy" /usr/local/bin/agy
install -m 644 config/fish/conf.d/antigravity.fish ~/.config/fish/conf.d/antigravity.fish

# IDE apt repo
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
echo 'deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main' | \
  sudo tee /etc/apt/sources.list.d/antigravity.list
sudo apt-get update -y
sudo apt-get install -y antigravity

sudo install -m 755 config/bin/antigravity-crostini /usr/local/bin/antigravity-crostini
sudo ln -sfn /usr/local/bin/antigravity-crostini /usr/local/bin/antigravity
sudo install -m 644 config/desktop/antigravity.desktop /usr/share/applications/antigravity.desktop

mkdir -p ~/.config/Antigravity
printf '%s\n' '{' '  "disable-hardware-acceleration": true' '}' \
  > ~/.config/Antigravity/argv.json

agy --version
antigravity &
```

**Config** — wrapper `config/bin/antigravity-crostini` execs `/usr/share/antigravity/bin/antigravity` with `--ozone-platform=x11 --disable-gpu --disable-gpu-compositing --disable-dev-shm-usage --no-sandbox`. Desktop `Exec=/usr/local/bin/antigravity-crostini %F`.

Seed: package **1.23.2** / app **1.107.0** · CLI **1.1.12**. Updates: in-app or `sudo apt-get install -y antigravity`.

**Verify.**

```bash
dpkg -l antigravity
command -v antigravity agy
# window appears under Chrome OS (not blank)
```

**Backout.**

```bash
sudo apt-get remove --purge -y antigravity
sudo rm -f /usr/local/bin/antigravity /usr/local/bin/antigravity-crostini /usr/local/bin/agy
rm -f ~/.local/bin/agy ~/.config/fish/conf.d/antigravity.fish
```

---

### CHG-007 — Disk resize

> Applied · 2026-08-12 · Low

**Why this step.** Stock ~10 GiB fills after WebKit + Electron + Spotify. This is why the later chapters fit.

**Surfaces.** Chrome OS Settings → Linux → **Disk size**. Guest: `/dev/vdb` (btrfs on seed).

**Script.** none — host control plane.

**Manual.**

1. **Settings → Developers → Linux development environment → Disk size**.  
2. Set target (seed: **213 GiB**).  
3. Apply; wait.  
4. Confirm:

```bash
df -h /
lsblk -f
# seed: ~213G on /dev/vdb
```

**Backout.** n/a. Shrinking is rarely worth it.

---

### CHG-008 — Git SSH on fish

> Applied · 2026-08-13 · Low

**Why this step.** Clone this kit over SSH. Bash `eval "$(ssh-agent -s)"` is a syntax error in fish.

**Surfaces.** `~/.ssh/id_ed25519` · `known_hosts` · GitHub SSH keys.

**Script.** none.

**Manual.**

```fish
ssh-keygen -t ed25519 -C "you@example.com"
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
# paste into GitHub → Settings → SSH keys
ssh -T git@github.com
git clone git@github.com:SOC-Foundry/crostini.git ~/projects/sf/crostini
```

**Verify.**

```fish
ssh-add -l
ssh -T git@github.com
git -C ~/projects/sf/crostini remote -v
```

**Backout.**

```fish
ssh-add -d ~/.ssh/id_ed25519 2>/dev/null
rm -f ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
# remove the key from GitHub
```

Never commit the private key.

---

### CHG-009 — Spotify desktop

> Applied · 2026-08-14 · Low–Med

**Why this step.** Music is part of the desktop. Official Linux client, same CEF trap as Antigravity, same Pulse socket Crostini already provides.

**Surfaces.** apt `spotify-client` · `/usr/bin/spotify` · `/usr/local/bin/spotify-crostini` · `/usr/share/applications/spotify.desktop` · `~/.local/share/applications/spotify.desktop` · `~/.config/spotify/Users/*/prefs`.

**Script.** `./scripts/install-spotify.sh`

**Manual.**

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc \
  | sudo gpg --dearmor --yes -o /etc/apt/keyrings/spotify.gpg
echo 'deb [signed-by=/etc/apt/keyrings/spotify.gpg] https://repository.spotify.com stable non-free' \
  | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update
sudo apt-get install -y spotify-client

sudo install -m 755 config/bin/spotify-crostini /usr/local/bin/spotify-crostini
sudo ln -sfn /usr/local/bin/spotify-crostini /usr/local/bin/spotify

mkdir -p ~/.local/share/applications
sudo cp -a /usr/share/applications/spotify.desktop \
  /usr/share/applications/spotify.desktop.bak.chg009.$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
sudo install -m 644 config/desktop/spotify.desktop /usr/share/applications/spotify.desktop
install -m 644 config/desktop/spotify.desktop ~/.local/share/applications/spotify.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true

spotify &
```

**Config** — wrapper (`config/bin/spotify-crostini`):

```bash
#!/usr/bin/env bash
set -euo pipefail
BIN="/usr/bin/spotify"
[ -x "$BIN" ] || { echo "missing $BIN" >&2; exit 1; }
export ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-x11}"
unset WAYLAND_DISPLAY 2>/dev/null || true
exec "$BIN" \
  --ozone-platform=x11 \
  --disable-gpu \
  --disable-gpu-compositing \
  --disable-dev-shm-usage \
  --no-sandbox \
  --audio-api=pulseaudio \
  "$@"
```

Desktop (`config/desktop/spotify.desktop`):

```ini
[Desktop Entry]
Name=Spotify
Comment=Spotify desktop (Crostini wrapper)
Exec=/usr/local/bin/spotify-crostini %U
TryExec=/usr/local/bin/spotify-crostini
Icon=spotify-client
Type=Application
Terminal=false
StartupNotify=true
StartupWMClass=spotify
Categories=Audio;Music;Player;AudioVideo;
MimeType=x-scheme-handler/spotify;
```

Very High (~320 kbit/s, enumeration `4`) after first sign-in — installer merges these into `~/.config/spotify/Users/*/prefs` (or GUI: **Settings → Audio Quality → Very high**). Premium required. Do not commit that prefs file (autologin blobs).

```
audio.play_bitrate_non_metered_migrated=true
audio.sync_bitrate_enumeration=4
audio.play_bitrate_enumeration=4
audio.play_bitrate_non_metered_enumeration=4
```

Seed: **spotify-client 1:1.2.95.453.g0eeebbed**. Do not replace PipeWire/Pulse. Host volume is Chrome OS.

**Verify.**

```bash
test -x /usr/bin/spotify
test -x /usr/local/bin/spotify-crostini
test -f /usr/share/applications/spotify.desktop
test -f ~/.local/share/applications/spotify.desktop
grep -q spotify-crostini /usr/share/applications/spotify.desktop
dpkg-query -W spotify-client
pactl get-default-sink
grep -E '^audio\.(play|sync)_bitrate' ~/.config/spotify/Users/*/prefs
pgrep -a spotify
```

Launcher: **Linux apps → Spotify**. If the files exist but the folder is empty: **Settings → Developers → Linux → Restart**. Sign in in the GUI; play one track.

**Backout.**

```bash
sudo apt-get remove --purge -y spotify-client
sudo rm -f /etc/apt/sources.list.d/spotify.list /etc/apt/keyrings/spotify.gpg
sudo rm -f /usr/local/bin/spotify /usr/local/bin/spotify-crostini
sudo rm -f /usr/share/applications/spotify.desktop
rm -f ~/.local/share/applications/spotify.desktop
sudo apt-get update
rm -rf ~/.config/spotify ~/.cache/spotify
```

---

### CHG-010 — inxi hardware probe

> Applied · 2026-08-14 · Low

**Why this step.** You need a one-liner for machine + CPU + RAM in the VM. Crostini is a guest: `-M` is crosvm, `-C` is the real CPU. The Latitude / SSD / battery live on the Chrome OS host — there is no `inxi` there.

**Surfaces.** packages `inxi`, `dmidecode` · `/usr/bin/inxi` · crosh on the host.

**Script.** none — also added to `scripts/bootstrap.sh`.

**Manual.**

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends inxi dmidecode
```

`--no-install-recommends` skips `mesa-utils` / `lm-sensors` (unused by `-MC`).

Two spec commands after install:

```bash
# VM — penguin
inxi -MCzm
```

```text
# Host — crosh (Ctrl+Alt+T). Not inxi.
battery_test 1
storage_status
```

`inxi -MC` is enough if you do not need RAM. `sudo inxi -MC` only adds DMI serial. Daily use does not need sudo. Host extras: **About ChromeOS → Additional details**, `chrome://system`.

**Config.** none.

**Verify.**

```bash
command -v inxi
dpkg-query -W inxi dmidecode
inxi -c 0 -MCzm
```

Seed (2026-08-14, **inxi 3.3.38-1-1**):

```text
Machine:
  Type: N/A System: ChromiumOS product: crosvm v: N/A serial: N/A
  Mobo: N/A model: N/A serial: N/A BIOS: crosvm v: N/A date: N/A
Memory:
  System RAM: total: 16 GiB note: est. available: 14.07 GiB
CPU:
  Info: 8x 1-core model: Intel Core i7-8665U bits: 64 type: SMP cache: L2: 8x 256 KiB (2 MiB)
  Speed (MHz): avg: 2112 min/max: N/A cores: 1: 2112 … 8: 2112
```

`-M` = crosvm is correct. Do not install `lshw` expecting a Latitude dump.

**Backout.**

```bash
sudo apt-get remove --purge -y inxi
# leave dmidecode
```

---

### CHG-011 — Alacritty banner + ~/projects/sf

> Applied · 2026-08-14 · Low

**Why this step.** The banner should show **VM** and **host** specs together, then land where this kit actually lives. There is no `/projects` on Crostini — the path is **`~/projects/sf`**.

**Surfaces.** `~/.local/bin/alacritty-crostini-banner` · `~/.config/crostini/host-specs.txt` · `~/.config/alacritty/alacritty.toml`

**Script.** `./scripts/bootstrap.sh`

**Manual.**

```bash
mkdir -p ~/.local/bin ~/.config/crostini ~/projects/sf
install -m 755 config/bin/alacritty-crostini-banner ~/.local/bin/alacritty-crostini-banner
install -m 644 config/alacritty/host-specs.txt ~/.config/crostini/host-specs.txt
# alacritty [terminal.shell] program = $HOME/.local/bin/alacritty-crostini-banner
```

Banner still runs `uname`, `ip -4 -br addr`, `lsblk -f`, `fastfetch`, then:

```text
=== VM (penguin) ===
inxi -c 0 -MCzm

=== HOST (Chrome OS Flex) ===
# from ~/.config/crostini/host-specs.txt  (Latitude 7200 · crosh hints)
# Flex has no inxi; refresh: crosh battery_test 1 · storage_status
```

Then `cd ~/projects/sf` and `exec fish -l`.

**Config.** `config/bin/alacritty-crostini-banner` · `config/alacritty/host-specs.txt`

**Verify.** Open **Alacritty**. Prompt cwd is `~/projects/sf`. Banner has both VM inxi and HOST block.

```bash
test -x ~/.local/bin/alacritty-crostini-banner
grep alacritty-crostini-banner ~/.config/alacritty/alacritty.toml
```

**Backout.** Restore `~/.config/alacritty/alacritty.toml.bak.chg011.*`

---

### CHG-012 — 1Password · personal GitHub SSH agent

> Applied · 2026-08-15 · Med

**Why this step.** npm supply-chain work I get hired for almost always begins with a GitHub private key on a laptop disk. I have not seen that pattern survive a shop that actually enforced a vaulted SSH agent. Personal GitHub is not exempt. CHG-008 left `id_ed25519` on penguin; this chapter moves it into 1Password. First idea was an existing **Bitwarden** account + “CLI SSH agent”; `bw` cannot sign, and Bitwarden’s Linux agent is weaker (no apt channel). Applied: **1Password** desktop as the agent for **personal `github.com` only**. Island is work (Workspace / Zoom / Slack), not part of this.

**Surfaces.** apt `1password` **8.12.32** · `1password-cli` **2.39.0** · `/usr/local/bin/1password-crostini` · `~/.ssh/config` (`Host github.com ssh.github.com`) · `~/.1password/agent.sock` · item `github-personal-ed25519`

**Script.** `./scripts/install-1password.sh`

**Human.** Settings → Developer → **Use the SSH Agent**. Import the existing key in the app (not `op` — CLI cannot import). Verify `ssh -T git@github.com`, then `shred -u ~/.ssh/id_ed25519`. Seed: shredded 2026-08-15; GitHub still `Hi kylejeromethompson!`.

Do **not** set `SSH_AUTH_SOCK` globally. Do **not** use `Host *`. Do **not** install the 1Password extension in Island.

Long form (Bitwarden detour, CLI limits, import, shred): [`docs/chg012-1password-ssh-agent.md`](docs/chg012-1password-ssh-agent.md).

**Verify.**

```bash
dpkg-query -W 1password 1password-cli
test -S ~/.1password/agent.sock
ssh -G github.com | grep -i identityagent
ssh -T git@github.com
test ! -e ~/.ssh/id_ed25519
```

**Backout.** Restore `~/.ssh/config.bak.chg012.*`. `sudo apt-get remove --purge -y 1password 1password-cli` and remove the wrapper / desktop files.

---

### CHG-013 — Cloudflare personal DNS

> Applied · 2026-08-18 · Med

**Why this step.** Hotel DNS is hostile. Penguin inherits `172.20.0.1`. Official **WARP** (personal free) **cannot start** here: guest kernel has no `ip rule` (`RTM_GETRULE` → EOPNOTSUPP); `sudo` does not help. Applied: **`dnscrypt-proxy` DoH** to Families **1.1.1.3** (`cloudflare-family`). Not plaintext DHCP to 1.1.1.x. Not Zero Trust. Not host Chrome. Not a browser chapter (014).

**Surfaces.** apt `dnscrypt-proxy` **2.1.8** · `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` · `/etc/resolv.conf` (regular file → `127.0.2.1`) · `/usr/local/bin/cf-dns-crostini` · `crostini-cf-dns.service`

**Script.** `./scripts/install-cf-dns.sh` (`install-warp.sh` execs the same).

**Manual.**

```bash
sudo apt-get install -y --no-install-recommends dnscrypt-proxy ca-certificates
sudo install -m 644 config/dnscrypt/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo install -m 755 config/bin/cf-dns-crostini /usr/local/bin/cf-dns-crostini
sudo install -m 644 config/systemd/crostini-cf-dns.service /etc/systemd/system/crostini-cf-dns.service
sudo systemctl daemon-reload
sudo systemctl enable --now dnscrypt-proxy.socket
sudo systemctl restart dnscrypt-proxy.service
cf-dns-crostini on
```

Hotel portal: `cf-dns-crostini off` → complete portal in **Chrome OS Chrome** → `cf-dns-crostini on`.

Host Chrome is separate: **Settings → Privacy and security → Use secure DNS → Cloudflare**. Do not enroll a work Cloudflare One / Teams org. Do not `tee` through the `/etc/resolv.conf` symlink (that overwrites `/run/resolv.conf`).

`cdn-cgi/trace` showing `warp=off` is correct — there is no traffic tunnel.

Long form (WARP attempt, `ip rule`, pin): [`docs/chg013-cloudflare-personal-dns.md`](docs/chg013-cloudflare-personal-dns.md).

**Verify.**

```bash
dpkg-query -W dnscrypt-proxy
ss -lun | grep 127.0.2.1:53
grep 127.0.2.1 /etc/resolv.conf
test ! -L /etc/resolv.conf
sudo journalctl -u dnscrypt-proxy -n 15 --no-pager   # [cloudflare-family] OK (DoH)
getent ahostsv4 cloudflare.com
```

**Backout.** `cf-dns-crostini off`. `sudo apt-get remove --purge -y dnscrypt-proxy` and remove the helper / pin unit.

Optional Gateway CA (still this chapter, not 014): `./scripts/install-cf-ca.sh /path/to/certificate.pem` — needs a current Zero Trust PEM; public sample expired 2025-02-02.

---

### CHG-014 — Debian Chromium

> Applied · 2026-08-18 · Low–Med

**Why this step.** Island is work. Host Chrome is the personal Google profile on Flex. Penguin still needs a personal Linux-apps browser. **Firefox** loses here: no GPU, WebRender jank, Debian only has **ESR 140**. **Opera** is a Blink fork not in Debian — vendor repo, extra daemons, more RAM, no feature Chromium 150 lacks that host Chrome does not already cover. Applied: Debian **`chromium` 150** + X11 / no-GPU / no-sandbox wrapper. **Two tabs max** (guest RAM). Not a DNS/WARP chapter (that is 013).

**Surfaces.** apt `chromium` **150.0.7871.100** · `/usr/bin/chromium` · `/usr/local/bin/chromium-crostini` · `/usr/local/share/crostini/chromium-2tab` · `/etc/chromium.d/crostini-2tab` · Linux apps **Chromium**

**Script.** `./scripts/install-chromium.sh`

**Manual.**

```bash
sudo apt-get install -y --no-install-recommends chromium
sudo install -m 755 config/bin/chromium-crostini /usr/local/bin/chromium-crostini
sudo ln -sfn /usr/local/bin/chromium-crostini /usr/local/bin/chromium
sudo mkdir -p /usr/local/share/crostini/chromium-2tab /etc/chromium.d
sudo install -m 644 config/chromium/2tab/* /usr/local/share/crostini/chromium-2tab/
sudo install -m 644 config/chromium/chromium.d-crostini-2tab /etc/chromium.d/crostini-2tab
sudo install -m 644 config/desktop/chromium.desktop /usr/share/applications/chromium.desktop
```

Personal only. Do not use for work SSO. No Widevine / no Google sync — host Chrome keeps those. `--password-store=basic`. A third tab is closed; the two most recently used stay.

Long form: [`docs/chg014-chromium.md`](docs/chg014-chromium.md).

**Verify.**

```bash
dpkg-query -W chromium
test -x /usr/local/bin/chromium-crostini
test -f /usr/local/share/crostini/chromium-2tab/manifest.json
grep chromium-crostini /usr/share/applications/chromium.desktop
chromium --version
```

**Backout.** `sudo apt-get remove --purge -y chromium chromium-common` and remove the wrapper / desktop files.

---

### CHG-015 — btop

> Applied · 2026-08-18 · Low  
> Operator-verified · 2026-08-19 · `penguin`

**Why this step.** Guest RAM is the scarce resource (Island + Chromium + Antigravity). `inxi` (010) is a snapshot. Need a live CPU / RAM / disk / net / process view of **penguin**, not the Latitude host. Debian ships **btop**; no extra repo.

**Surfaces.** apt `btop` **1.3.2** · `/usr/bin/btop` · `/usr/local/bin/btop-crostini` · `~/.config/btop/btop.conf` · Linux apps **btop**

**Script.** `./scripts/install-btop.sh`

**Manual.**

```bash
sudo apt-get install -y --no-install-recommends btop
sudo install -m 755 config/bin/btop-crostini /usr/local/bin/btop-crostini
sudo install -m 644 config/desktop/btop.desktop /usr/share/applications/btop.desktop
install -m 644 config/desktop/btop.desktop ~/.local/share/applications/btop.desktop
install -m 644 config/btop/btop.conf ~/.config/btop/btop.conf
```

In a terminal: `btop`. From Chrome OS: **Linux apps → btop** (Alacritty). Vendor `btop.desktop` is `Terminal=true` and would open Chrome OS Terminal — the wrapper replaces it. Seed operator confirmed both paths on 2026-08-19.

CPU / RAM / disk / net are the guest. No GPU. Temps usually empty. Battery, if shown, is virtio; crosh `battery_test 1` is the host check. Do not install `lm-sensors` for a Latitude dump.

**Config.** `config/btop/btop.conf` → `~/.config/btop/btop.conf`. Penguin has **no `/etc/fstab`**; default `use_fstab = True` logs `Mem::collect()` errors. Kit pins `use_fstab = False`, `check_temp = False`, `show_gpu_info = "Off"`, `net_iface = "eth0"`.

`/usr/bin/btop` stays the binary. Do not alias `btop` to the wrapper.

Long form: [`docs/chg015-btop.md`](docs/chg015-btop.md).

**Verify.**

```bash
dpkg-query -W btop
btop --version
test -x /usr/local/bin/btop-crostini
grep btop-crostini /usr/share/applications/btop.desktop
grep 'use_fstab = False' ~/.config/btop/btop.conf
```

**Backout.** `sudo apt-get remove --purge -y btop` and remove the wrapper / desktop files.

---

## 7 · Repository layout

```text
README.md                 ← you are here
AGENTS.md                 ← agent policy (no git commit/push)
docs/
  architecture.md
  disk-and-persistence.md
  troubleshooting.md
  chg-ledger.md
  handoff.md              ← seed-host continuity
  chg001-…chg015-*.md     ← chapter detail
  archive/                ← legacy session dumps (do not use as source of truth)
scripts/
  bootstrap.sh            ← CHG-001 · 002 · 010 · 011
  install-grok.sh         ← CHG-005
  ensure-grok
  install-island.sh       ← CHG-003
  install-antigravity.sh  ← CHG-006
  install-spotify.sh      ← CHG-009
  install-1password.sh    ← CHG-012
  install-cf-dns.sh       ← CHG-013
  install-warp.sh         ← alias → install-cf-dns.sh
  install-chromium.sh     ← CHG-014
  install-btop.sh         ← CHG-015
  install-cf-ca.sh        ← CHG-013 optional Gateway CA
  verify.sh
config/
  alacritty/              # toml + host-specs.txt
  fish/conf.d/
  bin/                    # antigravity · spotify · 1password · alacritty-crostini-banner · cf-dns · chromium · btop
  desktop/
  btop/                   # use_fstab=False (no /etc/fstab on penguin)
  ssh/                    # GitHub-only IdentityAgent snippet
  spotify/prefs.high-quality
  dnscrypt/               # Families DoH toml + resolv stub
  systemd/                # crostini-cf-dns.service
```

---

## 8 · Non-goals

| Out of scope | Why |
|--------------|-----|
| Replacing Chrome OS as host | Flex/Chrome OS stays the thin manager |
| Hyprland / multi-monitor host config | Host windowing is Chrome OS |
| LUKS data partitions on the Chrome disk | Wrong layer; use Crostini disk resize |
| Host WirePlumber / Bluetooth policy | Owned by Chrome OS |
| Snap / Flatpak for this kit | Extra daemons; seed has neither |
| Shipping vendor `.deb` blobs in git | License + size — stage locally |
| Claiming “native Chromebook only” | **Flex on ordinary PCs is first-class** |
| Official Cloudflare WARP tunnel on penguin | Guest kernel has no `ip rule`; Crostini `100.115/172.20` must stay on eth0 |
| Chrome OS host WARP / host partition DNS | Wrong layer; host **Use secure DNS** is Settings-only |

---

## 9 · Changelog

Complete ledger for the seed host **`penguin`** (Dell Latitude 7200 · Chrome OS Flex · Debian 13 Crostini). Ordered by apply time. Numbers are the **canonical CHG-00N** for this repository.

| Applied | CHG | Title | Status | Risk | Surfaces |
|---------|-----|--------|--------|------|----------|
| 2026-08-12 | [001](#chg-001--fish--tide--done) | Fish · Tide · done · readable paths · bash handoff | Applied | Low | `fish` · fisher · Tide · `~/.bashrc` |
| 2026-08-12 | [002](#chg-002--alacritty-startup) | Alacritty startup banner | Applied | Low | `alacritty` · `fastfetch` · `alacritty.toml` |
| 2026-08-12 | [003](#chg-003--island-browser) | Island browser **151.1.97.29** | Applied | Low–Med | `island-browser-stable` · Linux apps |
| 2026-08-12 | [004](#chg-004--wasistlos-whatsapp) | WasIstLos **1.7.0** (WhatsApp Web) | Applied | Low | `wasistlos` · WebKit stack |
| 2026-08-12 | [005](#chg-005--agent-cli-permanent-install) | Grok Build **1.0.3** permanent PATH | Applied | Low | `~/.grok` · `/usr/local/bin/grok` · profile.d · fish conf.d |
| 2026-08-12 | [006](#chg-006--antigravity-ide--cli) | Antigravity IDE **1.107.0** (pkg 1.23.2) · CLI **1.1.12** · Crostini wrapper | Applied | Low–Med | apt · `agy` · `antigravity-crostini` |
| 2026-08-12 | [007](#chg-007--disk-resize) | Crostini disk **10 GiB → 213 GiB** | Applied | Low | Chrome OS Settings · btrfs `/dev/vdb` |
| 2026-08-13 | [008](#chg-008--git-ssh-on-fish) | Git SSH ed25519 · fish agent · clone this repo | Applied | Low | `~/.ssh` · GitHub · `~/projects/sf/crostini` |
| 2026-08-14 | [009](#chg-009--spotify-desktop) | Spotify **1.2.95.453** · Crostini wrapper | Applied | Low–Med | `spotify-client` · `spotify-crostini` · Linux apps |
| 2026-08-14 | [010](#chg-010--inxi-hardware-probe) | inxi **3.3.38** · VM `inxi -MCzm` · host crosh `battery_test` / `storage_status` | Applied | Low | `inxi` · `dmidecode` · crosh |
| 2026-08-14 | [011](#chg-011--alacritty-banner--projectssf) | Alacritty banner: VM+host specs · land **`~/projects/sf`** | Applied | Low | `alacritty-crostini-banner` · `host-specs.txt` |
| 2026-08-15 | [012](#chg-012--1password-personal-github-ssh-agent) | 1Password desktop · personal GitHub SSH agent | Applied | Med | `1password` · `1password-crostini` · `~/.ssh/config` |
| 2026-08-18 | [013](#chg-013--cloudflare-personal-dns) | Cloudflare 1.1.1.1 for Families (malware + adult, 1.1.1.3) DoH; official WARP blocked | Applied | Med | `dnscrypt-proxy` · `cf-dns-crostini` · `/etc/resolv.conf` |
| 2026-08-18 | [014](#chg-014--debian-chromium) | Debian Chromium **150** personal Linux browser, 2 tabs | Applied | Low–Med | `chromium` · `chromium-crostini` · `chromium-2tab` |
| 2026-08-18 | [015](#chg-015--btop) | btop **1.3.2** guest resource TUI · Alacritty launcher (operator-verified 2026-08-19) | Applied | Low | `btop` · `btop-crostini` |

### Software inventory (seed, post-changelog)

| Package / binary | Role |
|------------------|------|
| `fish` 4.x · Tide · done | Shell |
| `alacritty` · `fastfetch` | Terminal |
| `git` · `openssh-client` | SCM |
| `island-browser` | Work browser (Workspace / Zoom / Slack) |
| `chromium` **150.0.7871.100** · `chromium-crostini` | Personal Linux browser (2 tabs) |
| `wasistlos` | WhatsApp |
| `spotify-client` **1.2.95.453** · `spotify-crostini` | Music |
| `antigravity` · `agy` | IDE + agent CLI |
| `grok` (optional) | Agent CLI |
| `fonts-powerline` · emoji fonts | Prompt glyphs |
| `inxi` **3.3.38** · `dmidecode` | Guest probe (`inxi -MCzm`); host specs via crosh |
| `1password` **8.12.32** · `1password-cli` **2.39.0** · `1password-crostini` | Personal GitHub SSH agent (github.com only) |
| `dnscrypt-proxy` **2.1.8** · `cf-dns-crostini` | Personal Cloudflare Families malware + adult DoH (1.1.1.3 → 127.0.2.1) |
| `btop` **1.3.2** · `btop-crostini` | Guest resource TUI (CPU / RAM / disk / net); Linux apps via Alacritty |

That table is the current seed: a Flex Latitude 7200 whose Linux VM boots to fish, opens Alacritty, and can launch Chromium, Island, WhatsApp, Spotify, Antigravity, 1Password, and btop from **Linux apps**. Guest CPU via inxi is i7-8665U; chassis string is crosvm. Penguin DNS on public Wi‑Fi is Cloudflare Families over DoH.

### Next free

**CHG-016** — Nerd Font pin for Tide · Share with Linux runbook.

---

## Credits

- Platform: [Chrome OS Flex](https://chromeos.google/products/chromeos-flex/) · Crostini · Debian  
- Shell: [fish](https://fishshell.com/) · [fisher](https://github.com/jorgebucaran/fisher) · [Tide](https://github.com/IlanCosman/tide) · [done](https://github.com/franciscolourenco/done)  
- Terminal: [Alacritty](https://alacritty.org/)  
- IDE: [Google Antigravity](https://antigravity.google/download/linux)  
- Music: [Spotify for Linux](https://www.spotify.com/us/download/linux/)  
- Vault / SSH agent: [1Password for Linux](https://support.1password.com/install-linux/)  
- Hardware probe: [inxi](https://smxi.org/docs/inxi.htm) (guest); crosh on the host  
- Resource TUI: [btop](https://github.com/aristocratos/btop) (guest)  
- DNS: [1.1.1.1 for Families](https://developers.cloudflare.com/1.1.1.1/1.1.1.1-for-families/) via [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy) (official WARP client cannot run on Crostini)  
- Personal Linux browser: Debian [Chromium](https://wiki.debian.org/Chromium)  

---

## License

MIT. Config and scripts are free to copy. Do not commit secrets, private keys, or vendor `.deb` files.

---

<sub>Seed · penguin · Latitude 7200 · Flex · 2026-08-12 → 2026-08-19 · CHG-001…015</sub>
