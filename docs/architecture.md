# Architecture — Chrome OS Flex · Crostini · Grok

## Three layers

```text
┌─────────────────────────────────────────────┐
│  Chrome OS Flex (host)                      │
│  · Window manager, audio, GPU, Files app    │
│  · Linux disk size setting (seed: 213 GiB)  │
├─────────────────────────────────────────────┤
│  Crostini VM (penguin / Debian)             │
│  · apt packages, ~/.config, login shell     │
│  · Alacritty, fish, Tide, Island, Antigravity
│  · Survives host reboot (unless Linux Remove)
├─────────────────────────────────────────────┤
│  Grok Build (~/.grok)                       │
│  · CLI binary + auth.json + sessions        │
│  · Persistent on /dev/vdb                   │
│  · Discoverable via profile.d + /usr/local  │
└─────────────────────────────────────────────┘
```

## Persistence model

| Asset | Survives Chrome OS reboot? |
|-------|----------------------------|
| Crostini rootfs packages | **Yes** (unless Linux is removed or disk wiped) |
| `~/.config/fish`, Alacritty | **Yes** |
| `~/.grok` (binary, auth, sessions) | **Yes** |
| `PATH` if only set in a one-off shell | **No** — fixed by CROS-004 hooks |
| After **Settings → Developers → Linux → Remove** | **No** — full reinstall |

## Display & input

- Sommelier bridges Wayland/X: `DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-0`
- Alacritty and Island run as Linux apps under the Chrome OS launcher
- Clipboard: OSC52 in Alacritty (`osc52 = "CopyPaste"`)
- Electron (Antigravity) needs the Crostini wrapper: X11 + `--disable-gpu` + `--no-sandbox` (no DRM nodes in the VM)
- Island on this Flex host needed **no** extra GPU flags

## Shared files (CROS-007 / 008)

Chrome OS **My files** is not in penguin until you:

1. Drag into **Linux files**, or
2. Right-click a folder → **Share with Linux** → `/mnt/chromeos/MyFiles/…`

## What we do not own

- Hyprland / host window manager binds
- Host audio (WirePlumber lives on Chrome OS)
- Partitioning the virtual disk as LUKS/XFS `/data`

Stay in the container. Resize disk from **Chrome OS Settings → Linux**.
