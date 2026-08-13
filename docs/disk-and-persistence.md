# Disk & persistence

## Default vs seed host

Stock Crostini often ships **~10 GiB**. Fine for a lean shell; tight for browser + IDE.

Seed host (`penguin`, Latitude 7200 · Flex) resized **10 GiB → 213 GiB** btrfs (`/dev/vdb`) — **CHG-007**.

## Resize

**Settings → Developers → Linux development environment → Disk size**

| Profile | Rough need |
|---------|------------|
| Lean terminal (CHG-001 · 002) | &lt; 2 GiB used |
| + Island | + ~0.8 GiB |
| + Antigravity | + ~0.9 GiB |
| + WasIstLos (WebKit) | multi-hundred MiB deps |
| Projects + toolchains | plan 20 GiB+ |

## Ephemeral vs permanent

| Myth | Reality |
|------|---------|
| “Everything dies on reboot” | Crostini disk **persists** |
| “Must reinstall the agent every boot” | Binary lives under `$HOME`; fix **PATH** (CHG-005) |
| “Resize needs repartition scripts” | Host setting only |

**Actually destructive:** Linux → **Remove**, or wipe the Flex install.
