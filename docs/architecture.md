# Architecture

## Three layers

```text
┌──────────────────────────────────────────────────────────┐
│  Chrome OS Flex (or Chrome OS) — host                    │
│  · Windowing, power, Files app, verified updates         │
│  · Linux disk size control plane                         │
├──────────────────────────────────────────────────────────┤
│  Crostini VM — hostname penguin · Debian                 │
│  · apt · ~/.config · login shell · Linux apps launcher   │
│  · Persistent across host reboot (until Linux is Removed)│
├──────────────────────────────────────────────────────────┤
│  Operator desktop (user-space)                           │
│  · fish · Alacritty · browsers · IDE · git SSH · agents  │
└──────────────────────────────────────────────────────────┘
```

**Thesis:** the host stays thin; the **VM is the desktop** an Arch-minded developer actually uses.

## Persistence

| Asset | Survives Chrome OS reboot? |
|-------|----------------------------|
| apt packages, `~/.config`, `~/.local` | **Yes** |
| `~/.ssh`, git clones under `$HOME` | **Yes** |
| Optional agent tree `~/.grok` | **Yes** (on Crostini disk) |
| PATH if only set in a one-off shell | **No** — see CHG-005 hooks |
| After **Linux → Remove** | **No** — container gone |

## Display

- Sommelier bridges Wayland/X (`DISPLAY=:0`, often `WAYLAND_DISPLAY=wayland-0`)
- Linux `.desktop` entries appear in the Chrome OS launcher
- Alacritty: OSC52 clipboard (`osc52 = "CopyPaste"`)
- Electron (Antigravity): use Crostini wrapper — X11 + `--disable-gpu` + `--no-sandbox` (no DRM nodes in the VM)
- Island on seed Flex host: no extra GPU flags required

## Shared files

Chrome OS **My files** is not in the VM until:

1. Drag into **Linux files**, or  
2. Right-click → **Share with Linux** → paths under `/mnt/chromeos/…`

## Boundaries

| Own in the VM | Do not own |
|---------------|------------|
| Shell, terminal, apt apps | Host window manager / Hyprland |
| User config under `$HOME` | Host audio policy |
| Crostini disk contents | Chrome OS system partitions |
