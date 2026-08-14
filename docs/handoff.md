# Handoff — seed host continuity

| | |
|---|---|
| Host | `penguin` · Chrome OS Flex · Debian 13 Crostini · Dell Latitude 7200 |
| Kit | this repo · `~/projects/sf/crostini` |
| Applied | **CHG-001 … CHG-011** (see README changelog) |
| Next free | **CHG-012** |

## Grok resume (if using Grok Build)

| Goal | Command |
|------|---------|
| Resume a specific session | `grok --resume <session-uuid>` |
| Continue latest for **this cwd** | `cd ~/projects/sf/crostini && grok -c` |

Sessions are scoped by working directory. `-c` does not jump across repos.

Historical omarchy-cwd session (pre-kit focus): `019ff5cd-60a4-7ba3-980c-ad03513e1ac3` — see `docs/archive/` for full pre-cleanup narrative.

## Live inventory (seed)

| Component | State |
|-----------|--------|
| Disk | 213 GiB btrfs |
| Shell | fish + Tide + done |
| Terminal | Alacritty + banner (inxi VM/host) → `~/projects/sf` |
| Browser | Island 151.x |
| Chat | wasistlos |
| IDE | antigravity (apt) + crostini wrapper · `agy` |
| Agent CLI | grok (optional permanent) |
| Music | spotify-client 1.2.95.453 + crostini wrapper |
| Git | ed25519 SSH → GitHub |
| Hardware probe | inxi 3.3.38 + dmidecode · `inxi -MC` (no sudo) |

## Agent policy

See root **AGENTS.md**: never `git add` / `git commit` / `git push`.
