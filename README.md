# crostini-grok

**Lean terminal kit for Chrome OS Flex / Crostini + [Grok Build](https://grok.com).**

Port of Omarchy’s CHG-style runbook to Debian-in-a-container: fish · Tide · Alacritty · **permanent** Grok PATH — plus optional Island browser and Antigravity IDE. No Hyprland, yay, or LUKS `/data` drama.

> One-line: a durable Linux **devshell** under a managed host OS, optimized for agent loops on Chromebooks.

## Who this is for

- Chrome OS Flex and Chromebook users who want a serious CLI agent workflow
- Operators who liked [SOC-Foundry/omarchy](https://github.com/SOC-Foundry/omarchy)’s ledger format but run Flex, not Arch desktops
- Anyone starting on a **10 GiB** Crostini disk who needs a lean profile first (resize before Island / Antigravity)

## 5-minute quickstart

1. Enable **Linux development environment** (Crostini) in Chrome OS Settings.
2. Open the Terminal app (hostname is usually `penguin`).
3. **Resize Linux disk** before optional apps (seed host: 10 GiB → 213 GiB).
4. Run:

```bash
# clone this repo, then:
./scripts/bootstrap.sh
./scripts/install-grok.sh     # skip curl if ~/.grok/bin/grok exists
./scripts/verify.sh
```

5. Launch **Alacritty** (banner + Tide) or **Grok Build** from the Chrome OS Linux apps launcher.

Optional (after disk resize):

```bash
./scripts/install-island.sh /path/to/island-browser-stable_*.deb
./scripts/install-antigravity.sh
```

## What you get

| Layer | Result |
|-------|--------|
| Shell | fish as login shell · Tide v6 Rainbow · done |
| Terminal | Alacritty with one-shot system banner → `~/projects` |
| Agent | **Permanent** Grok (`profile.d` + `/usr/local/bin/grok` + `ensure-grok`) |
| Optional apps | Island browser · Antigravity IDE (`agy` + Crostini wrapper) |
| Disk (seed) | 213 GiB btrfs · ~207 GiB free |

## Design principles

1. **Idempotent** — safe after reboot or partial failure; `ensure-grok` never curls if the binary exists
2. **Debian-first** — apt packages; local `.deb` via `apt install`, not bare `dpkg`
3. **No host drama** — never touch Chrome OS partitions
4. **Grok-aware** — profile.d + fish `conf.d` + absolute symlink
5. **Lean default** — terminal excellence; Island / Antigravity are optional chapters
6. **CHG-style ledger** — Objective · Challenge · Execute · Backout
7. **Explicit non-goals** — no Hyprland / LUKS data disks / host WirePlumber

## Repo layout

```text
README.md
docs/
  architecture.md
  chg-ledger.md
  disk-and-persistence.md
  troubleshooting.md
  chg012-island-browser-penguin.md
  chg013-014-penguin-grok-permanent-and-antigravity.md
  session-omarchy-port.md
scripts/
  bootstrap.sh
  install-grok.sh
  ensure-grok
  install-island.sh
  install-antigravity.sh
  verify.sh
config/
  alacritty/alacritty.toml
  fish/conf.d/grok.fish
  fish/conf.d/antigravity.fish
  bin/antigravity-crostini
  desktop/*.desktop
```

## Changelog chapters

| ID | Title | Status | Alias |
|----|-------|--------|-------|
| CROS-001 | Disk & persistence reality | done | — |
| CROS-002 | fish + Tide + done | done | omarchy CHG-002 |
| CROS-003 | Alacritty startup banner | done | omarchy CHG-003 |
| CROS-004 | Permanent Grok Build | done | penguin CHG-013 |
| CROS-005 | Nerd Font for Tide | planned | — |
| CROS-006 | Agent-friendly bash escape | done | — |
| CROS-007 | Shared folder workflow | planned | — |
| CROS-008 | Island browser | done | penguin CHG-012 |
| CROS-009 | Antigravity IDE + CLI | done | penguin CHG-014 |

See [docs/chg-ledger.md](docs/chg-ledger.md).

### Applied changelog rows (seed host `penguin` · 2026-08-12)

| Applied | CHG | Title | Status | Risk | Surfaces |
|---------|-----|-------|--------|------|----------|
| 2026-08-12 | [012](docs/chg012-island-browser-penguin.md) | Island browser on penguin | Applied | Low–Med | apt · Island `.deb` · Linux apps |
| 2026-08-12 | [013](docs/chg013-014-penguin-grok-permanent-and-antigravity.md) | Permanent Grok Build on Crostini | Applied | Low | `~/.grok` · profile.d · fish · `/usr/local/bin/grok` |
| 2026-08-12 | [014](docs/chg013-014-penguin-grok-permanent-and-antigravity.md) | Antigravity IDE apt + CLI + Crostini launch | Applied | Low–Med | apt `antigravity` · `agy` · crostini wrapper |

## Non-goals

Omarchy chapters that **do not** map to Flex/Crostini:

- Hyprland monitors / binds
- LUKS or XFS `/data` partitioning
- WirePlumber / host audio EQ
- Screenshot binds into `/data/.../ss`

Do **not** commit vendor `.deb` files.

## Credits

- Runbook format & CHG-002/003 intent: [SOC-Foundry/omarchy](https://github.com/SOC-Foundry/omarchy)
- Plugins: [fisher](https://github.com/jorgebucaran/fisher) · [tide](https://github.com/IlanCosman/tide) · [done](https://github.com/franciscolourenco/done)
- Antigravity: [download/linux](https://antigravity.google/download/linux)
- Platform: Chrome OS Flex · Crostini (Debian) · Grok Build by xAI

## Hardware note

First-class target: Flex on refurbished enterprise laptops (e.g. Latitude 7200, i7-class, ≥8 GiB visible to penguin). Document your CPU/RAM baseline when contributing.

## License

MIT. Config snippets are free to copy.
