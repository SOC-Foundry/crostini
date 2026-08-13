# Penguin session — Omarchy CHG-002 / 003 port

Seed write-up for the Crostini kit. Host: **penguin** · Chrome OS Flex · Debian 13 · Latitude 7200 · 2026-08-12.

## What we ported

| Omarchy | Crostini |
|---------|----------|
| CHG-002 fish + Tide + done | **CROS-002** — apt + Fisher curl + `sudo chsh` |
| CHG-003 Alacritty banner | **CROS-003** — Linux apps launcher, `cd ~/projects` |

Later the same session applied **CROS-004 / 008 / 009** (permanent Grok, Island, Antigravity). See [chg-ledger.md](chg-ledger.md).

## Why a literal replay fails

- `yay` / AUR do not exist — use apt + Fisher bootstrap
- `chsh` without sudo hits PAM on Crostini — `sudo chsh -s /usr/bin/fish $USER`
- Super+Return / Hyprland paths are meaningless
- `/data/Development/Projects` does not exist — use `~/projects`
- 10 GiB default disk — resize before Island / Antigravity (seed: 213 GiB)

## Persistence (the “ephemeral Grok” confusion)

| Layer | Survives Chrome OS reboot? |
|-------|----------------------------|
| Crostini rootfs + `~/.grok` | **Yes** unless Linux is removed |
| PATH if only set in a one-off shell | **No** — fixed by CROS-004 |
| After Settings → Linux → Remove | **No** |

## Reproduce

```bash
./scripts/bootstrap.sh
./scripts/install-grok.sh
./scripts/verify.sh
```

Optional apps after disk resize: `./scripts/install-island.sh …` and `./scripts/install-antigravity.sh`.

## Non-goals

Hyprland monitors, LUKS `/data`, WirePlumber host audio, screenshot binds into `/data/.../ss`.

Lineage: [SOC-Foundry/omarchy](https://github.com/SOC-Foundry/omarchy) for the CHG runbook format — not Hyprland compatibility.
