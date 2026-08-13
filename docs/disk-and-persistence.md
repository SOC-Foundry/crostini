# Disk & persistence

## Default budget vs seed host

Stock Crostini on many Flex images ships a **~10 GiB** virtual disk. That is enough for the **lean terminal** profile (~125 MB unpacked) and not enough for Island (~600 MiB installed) plus Antigravity (~700 MiB).

The seed host (`penguin`, Latitude 7200) resized **10 GiB → 213 GiB** btrfs (`/dev/vdb`) and had ~207 GiB free after CROS-008 / 009.

Grok itself is ~180 MiB under `~/.grok`.

## Resize (do this first for heavy work)

Chrome OS Settings → **Advanced** → **Developers** → **Linux development environment** → **Disk size**.

Plan headroom for:

| Profile | Rough need |
|---------|------------|
| Lean terminal (this kit) | < 2 GiB used |
| + Island browser | + ~0.8 GiB |
| + Antigravity IDE | + ~0.9 GiB |
| Node + a few projects | 8–15 GiB |
| Docker images | 20 GiB+ |
| Local models | tens of GiB |

## What is and isn’t ephemeral

- **Not ephemeral:** apt packages, fish/Tide, Alacritty, `~/.grok` (binary + `auth.json`), Island, Antigravity — they live on the Crostini disk.
- **Feels ephemeral:** `grok` missing from PATH after reboot because only bashrc was patched. Fixed by CROS-004 (`profile.d`, fish `conf.d`, `/usr/local/bin/grok`).
- **Actually gone:** Settings → Developers → Linux → **Remove**, or a wiped/resized-from-scratch disk.

## Guidance

1. Default profile = lean terminal kit.
2. Optional “apps” profile (Island + Antigravity) only after resize.
3. `verify.sh` prints free space every run.
4. Delete staged `.deb` files after Island install (~200 MiB).
