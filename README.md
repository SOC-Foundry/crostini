# crostini

**A real Linux desktop inside Chrome OS.**

For developers who live on Arch, Hyprland, and a carefully tuned shell — and want that same *operator* muscle memory on a Chromebook-class machine. Not a toy terminal. Not a cloud IDE. A **Debian Crostini VM** (`penguin`) running a full local stack: shell, terminal, browser, chat, agent tooling, SSH to GitHub.

> Proof point: an Arch-minded workflow can land on Crostini and stay productive with minimal host hardware — especially when the host is **Chrome OS Flex** on recycled enterprise iron.

```
Chrome OS Flex  →  Crostini (penguin)  →  fish · Alacritty · browsers · IDE · git
     host OS            Debian VM              your desktop, user-space only
```

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

Chromebooks (and Flex machines) are often dismissed as kiosk OS. That is incomplete.

Under the hood, **Crostini** gives you a real Linux container: `apt`, `systemd` user session, Wayland/X via sommelier, a persistent disk, and a Chrome OS app launcher that surfaces Linux `.desktop` entries. For someone who already ships on Arch, the mental model is:

| You already do | You do here |
|----------------|-------------|
| Own the shell | **fish** + Tide |
| Own the terminal | **Alacritty** |
| Own the browser | **Island** (or any `.deb`) |
| Own chat | **WasIstLos** (WhatsApp Web shell) |
| Own the IDE | **Antigravity** (apt + Crostini GPU flags) |
| Own git auth | **SSH ed25519** to GitHub |
| Own agents | Optional **Grok Build** (permanent install) |

The host stays managed and light. **All serious work happens in user-space inside the VM** — `~/.config/**`, `~/.local/**`, `/usr/local/bin`, apt packages. No dual-boot, no LUKS dance on the Chrome OS disk, no pretending crosh is enough.

This repository is the **runbook and scripts** for that proof — not a distro, not a Grok marketing page.

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

**Turn almost any old PC into a fully functional developer workstation** without buying a new machine and without carrying a second “real” laptop for Arch. The Latitude 7200 seed host is the existence proof: docked or undocked, Flex + Crostini + this ledger.

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

| | |
|---|---|
| Machine | Dell Latitude 7200 |
| Host OS | Chrome OS Flex |
| Container | `penguin` · Debian 13 (trixie) · x86_64 |
| Disk (final) | `/dev/vdb` · **213 GiB** btrfs |
| Kernel | Chrome OS guest kernel (`*-cros*`) |

Enough for shell + Alacritty + Island + Antigravity + agents. Resize early if you plan Electron apps.

---

## 5 · Quickstart

```bash
# inside penguin Terminal (or Alacritty after CHG-002)
sudo apt-get update
sudo apt-get install -y git

git clone git@github.com:SOC-Foundry/crostini.git ~/projects/sf/crostini
# or HTTPS if SSH is not set up yet:
# git clone https://github.com/SOC-Foundry/crostini.git ~/projects/sf/crostini

cd ~/projects/sf/crostini
chmod +x scripts/*
./scripts/bootstrap.sh          # fish · Tide · Alacritty · fonts
./scripts/install-grok.sh       # optional agent CLI — skip if you do not want it
./scripts/verify.sh
```

Optional:

```bash
./scripts/install-island.sh /path/to/island-browser-stable_*.deb
./scripts/install-antigravity.sh
```

Then open **Alacritty**, **Island**, **Antigravity**, or **WasIstLos** from the Chrome OS Linux apps launcher.

---

## 6 · Chapters (CHG ledger)

Chapters are numbered **from 1** in **apply order** on the seed host (`penguin`). Each chapter is user-space only.

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

Detail write-ups live under [`docs/`](docs/). Scripts under [`scripts/`](scripts/).

---

### CHG-001 — Fish · Tide · done

> Applied · 2026-08-12 · Low

**Objective.** Login shell is **fish** with **Tide** (Rainbow) and **done**; bash remains available for agents.

**Challenge.** Crostini is Debian (`apt`), not Arch. Plain `chsh` often fails PAM — use `sudo chsh`. Tide “many icons” needs powerline-capable fonts. Interactive bash entry points still appear; hand off to fish unless escaped.

**Surfaces.** `~/.config/fish/` · login shell · `~/.bashrc` handoff · fisher plugins.

**Execute (summary).**

```bash
sudo apt-get install -y fish fonts-powerline fonts-noto-color-emoji
# fisher + tide + done (see scripts/bootstrap.sh)
sudo chsh -s /usr/bin/fish "$USER"
# Tide: Rainbow, 16 colors, 24h, compact, many icons, transient
# Tide pwd: black on blue (readable)
# bash: exec fish on interactive TTY unless CROSTINI_BASH=1
```

**Verify.** `getent passwd $USER | cut -d: -f7` → `/usr/bin/fish` · `fisher list` includes tide + done.

**Backout.** Restore fish config backup · `sudo chsh -s /bin/bash "$USER"`.

---

### CHG-002 — Alacritty startup

> Applied · 2026-08-12 · Low

**Objective.** Linux terminal launches with a one-shot system snapshot, then interactive fish in `~/projects`.

**Challenge.** No Hyprland Super+Return. Landing path is `~/projects`, not a separate data volume.

**Surfaces.** `~/.config/alacritty/alacritty.toml` · package `alacritty` · `fastfetch`.

**Execute (summary).**

```bash
sudo apt-get install -y alacritty fastfetch
# shell: fish -l -c 'uname -a && ip -4 -br addr && lsblk -f && fastfetch; cd ~/projects; exec fish -l'
```

**Verify.** Open **Alacritty** from the Chrome OS launcher · banner then Tide prompt.

**Backout.** Remove or restore `alacritty.toml`.

---

### CHG-003 — Island browser

> Applied · 2026-08-12 · Low–Med

**Objective.** Full enterprise Chromium (**Island**) inside the VM for sites and SSO that need a real browser.

**Challenge.** Vendor `.deb` lives in Chrome OS Downloads until shared/copied into Linux. Install ~600 MiB; needs disk headroom.

**Surfaces.** `island-browser-stable` · `/usr/bin/island-browser` · Linux apps launcher.

**Execute (summary).**

```bash
# stage deb into Linux files, then:
./scripts/install-island.sh /path/to/island-browser-stable_*_amd64.deb
island-browser &
```

Seed version: **151.1.97.29**. No special GPU flags required on the seed host.

**Backout.** `sudo apt-get remove --purge -y island-browser-stable`.

---

### CHG-004 — WasIstLos (WhatsApp)

> Applied · 2026-08-12 · Low

**Objective.** Desktop WhatsApp via Debian’s **WasIstLos** (unofficial WhatsApp Web shell).

**Challenge.** No official Meta Linux client. WebKit stack pulls a large dependency tree.

**Surfaces.** package `wasistlos` · desktop **WasIstLos** · binary `wasistlos`.

**Execute.**

```bash
sudo apt-get install -y wasistlos
wasistlos &
# phone: Linked devices → scan QR
```

**Backout.** `sudo apt-get remove --purge -y wasistlos`.

---

### CHG-005 — Agent CLI permanent install

> Applied · 2026-08-12 · Low

**Objective.** Optional coding agent CLI (**Grok Build**) installed on the **persistent** Crostini disk so reboot does not require re-curl.

**Challenge.** Felt “ephemeral” because PATH was incomplete after `chsh` to fish and because reinstall was habitual. Binary already lived under `~/.grok` on `/dev/vdb`.

**Surfaces.** `~/.grok/` · `/usr/local/bin/grok` · `/etc/profile.d/grok.sh` · fish `conf.d` · `ensure-grok` · desktop launcher.

**Execute.**

```bash
./scripts/install-grok.sh    # curls only if missing
ensure-grok
grok --version
# updates: grok update
```

This chapter is **optional infrastructure**, not the thesis of the repo.

**Backout.** Remove symlinks, profile snippets, and optionally `~/.grok`.

---

### CHG-006 — Antigravity IDE · CLI

> Applied · 2026-08-12 · Low–Med

**Objective.** Google **Antigravity** IDE (apt, updatable) + **CLI** (`agy`), with a **Crostini-safe launcher** so the window is visible.

**Challenge.** Official Linux apt package is the IDE line (`antigravity`). Electron on Crostini often dies on Wayland/DRM (`drmGetDevices2`) → blank UI. Fix: X11 + disable GPU + no-sandbox wrapper.

**Surfaces.** apt `antigravity` · `/usr/share/antigravity/` · `agy` · `/usr/local/bin/antigravity-crostini` · desktop entry.

**Execute.**

```bash
./scripts/install-antigravity.sh
agy --version
antigravity &    # wrapper applies Crostini flags
```

Seed versions: IDE package **1.23.2** (app **1.107.0**) · CLI **1.1.12**.  
Update in-app or `sudo apt-get install -y antigravity`.

**Backout.** Purge apt package · remove `agy` · remove wrapper symlink.

---

### CHG-007 — Disk resize

> Applied · 2026-08-12 · Low

**Objective.** Grow Crostini root from default **~10 GiB** to **213 GiB** so browsers and IDEs fit.

**Challenge.** Stock disk fills after WebKit + Electron. Resize is a Chrome OS setting, not an in-VM partition script.

**Execute.** Settings → Linux → **Disk size** → apply. Confirm:

```bash
df -h /
# expect ~213G on seed host
```

**Backout.** n/a (host control plane). Shrinking is rarely worth it.

---

### CHG-008 — Git SSH on fish

> Applied · 2026-08-13 · Low

**Objective.** ed25519 key for GitHub; fish-correct `ssh-agent`; clone this kit over SSH.

**Challenge.** Bash snippets fail in fish:

```fish
# wrong
eval "$(ssh-agent -s)"
# right
eval (ssh-agent -c)
```

**Surfaces.** `~/.ssh/id_ed25519` · `known_hosts` · GitHub SSH keys.

**Execute.**

```fish
ssh-keygen -t ed25519 -C "you@example.com"
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
# add ~/.ssh/id_ed25519.pub to GitHub → Settings → SSH keys
ssh -T git@github.com
git clone git@github.com:SOC-Foundry/crostini.git ~/projects/sf/crostini
```

**Backout.** Remove key from GitHub · delete `~/.ssh/id_ed25519*`.

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
  chg001-…chg008-*.md     ← chapter detail
  archive/                ← legacy session dumps (do not use as source of truth)
scripts/
  bootstrap.sh            ← CHG-001 · 002
  install-grok.sh         ← CHG-005
  ensure-grok
  install-island.sh       ← CHG-003
  install-antigravity.sh  ← CHG-006
  verify.sh
config/
  alacritty/
  fish/conf.d/
  bin/antigravity-crostini
  desktop/
```
---

## 8 · Non-goals

| Out of scope | Why |
|--------------|-----|
| Replacing Chrome OS as host | Flex/Chrome OS stays the thin manager |
| Hyprland / multi-monitor host config | Host windowing is Chrome OS |
| LUKS data partitions on the Chrome disk | Wrong layer; use Crostini disk resize |
| Host WirePlumber / Bluetooth policy | Owned by Chrome OS |
| Shipping vendor `.deb` blobs in git | License + size — stage locally |
| Claiming “native Chromebook only” | **Flex on ordinary PCs is first-class** |

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

### Software inventory (seed, post-changelog)

| Package / binary | Role |
|------------------|------|
| `fish` 4.x · Tide · done | Shell |
| `alacritty` · `fastfetch` | Terminal |
| `git` · `openssh-client` | SCM |
| `island-browser` | Browser |
| `wasistlos` | WhatsApp |
| `antigravity` · `agy` | IDE + agent CLI |
| `grok` (optional) | Agent CLI |
| `fonts-powerline` · emoji fonts | Prompt glyphs |

### Next free

**CHG-009** — candidates: Nerd Font pin for Tide · Chrome OS “Share with Linux” automation · durable `ssh-agent` fish conf.d · drop optional `/opt` Antigravity tarball leftovers.

---

## Credits

- Platform: [Chrome OS Flex](https://chromeos.google/products/chromeos-flex/) · Crostini · Debian  
- Shell: [fish](https://fishshell.com/) · [fisher](https://github.com/jorgebucaran/fisher) · [Tide](https://github.com/IlanCosman/tide) · [done](https://github.com/franciscolourenco/done)  
- Terminal: [Alacritty](https://alacritty.org/)  
- IDE: [Google Antigravity](https://antigravity.google/download/linux)  

---

## License

MIT. Config and scripts are free to copy. Do not commit secrets, private keys, or vendor `.deb` files.

---

<sub>Seed · penguin · Latitude 7200 · Flex · 2026-08-12 → 2026-08-13 · CHG-001…008</sub>
