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
│  · fish · Alacritty · browsers · chat · music · IDE · git│
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
- Electron / CEF (Antigravity, Spotify, 1Password): Crostini wrapper — X11 + `--disable-gpu` + `--no-sandbox` (no DRM nodes in the VM)
- 1Password SSH agent is **Host github.com / ssh.github.com** only. Do not override global `SSH_AUTH_SOCK`.
- Spotify also forces `--audio-api=pulseaudio` so it uses the guest PipeWire-Pulse socket
- Island on seed Flex host: no extra GPU flags required
- Chromium (CHG-014): personal Linux browser, **two tabs max**. Wrapper execs `/usr/lib/chromium/chromium` (not Debian `/usr/bin/chromium`) with X11 + `--disable-gpu` + `--no-sandbox` + `--password-store=basic` + the 2-tab extension. Not Island. Not CHG-013.

## Hardware inventory

- Guest: `inxi -MC` (CHG-010, no sudo). `-M` is **crosvm / ChromiumOS**. `-C` is the host CPUID (seed: i7-8665U).
- Host model, SSD, battery, WLAN: Chrome OS About / `chrome://system` / crosh. Not apt. Do not install `lshw` expecting a Latitude dump.

## Shared files

Chrome OS **My files** is not in the VM until:

1. Drag into **Linux files**, or  
2. Right-click → **Share with Linux** → paths under `/mnt/chromeos/…`

## DNS

- Stock penguin: `/etc/resolv.conf` → `/run/resolv.conf` · `nameserver 172.20.0.1` (maitred / Chrome OS DNS proxy). Hotel DHCP is visible here.
- CHG-013 replaces `/etc/resolv.conf` with a **regular file** → `127.0.2.1` (`dnscrypt-proxy` DoH to Cloudflare Families malware + adult, 1.1.1.3). Do not `tee` through the symlink.
- Official `cloudflare-warp` / `warp-svc` **cannot run**: guest kernel has no policy routing (`ip rule` / RTM_GETRULE → EOPNOTSUPP).
- Host Chrome is a separate resolver (Chrome OS **Use secure DNS**). This chapter does not cover it.
- Personal only. Do not enroll Cloudflare One / Teams.
- Gateway inspection CA is optional **CHG-013**, not a browser chapter. System store + NSS. Not applied without a current PEM.

## Boundaries

| Own in the VM | Do not own |
|---------------|------------|
| Shell, terminal, apt apps | Host window manager / Hyprland |
| User config under `$HOME` | Host audio policy (speakers, Bluetooth) |
| Guest Pulse / pipewire-pulse clients | Replacing Crostini’s audio bridge |
| Penguin DNS stub (CHG-013) | Chrome OS host DNS / WLAN / captive portal |
| Crostini disk contents | Chrome OS system partitions |
