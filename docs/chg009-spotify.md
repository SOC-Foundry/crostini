# CHG-009 — Spotify desktop

> Applied · 2026-08-14 · `penguin` · Low–Med  
> README: [CHG-009](../README.md#chg-009--spotify-desktop) · Script: `scripts/install-spotify.sh`  
> Upstream: https://www.spotify.com/us/download/linux/

## Objective

Official **`spotify-client`** in the Chrome OS **Linux apps** launcher, with a Crostini wrapper so the CEF window is visible and audio uses the guest Pulse socket.

## Challenge

- Vendor apt repo (not in Debian).
- Spotify is Chromium/CEF. Sommelier advertises Wayland; no DRM nodes → blank UI without X11 + `--disable-gpu` + `--no-sandbox`.
- Newer clients can pick a non-Pulse audio backend and go silent. Crostini already runs PipeWire-Pulse — speak `--audio-api=pulseaudio`. Do **not** replace the guest audio stack.
- Host speakers / Bluetooth stay Chrome OS. Garcon only lists a valid `.desktop` on disk.
- Default stream is not Very High. Pin bitrate `4` (~320 kbit/s) in the **user** prefs after first sign-in. Premium required. Do not commit `~/.config/spotify/` (autologin blobs).

## Paths

- apt `spotify-client` → `/usr/bin/spotify` → `/usr/share/spotify/spotify`
- `config/bin/spotify-crostini` → `/usr/local/bin/spotify-crostini` · `/usr/local/bin/spotify`
- `config/desktop/spotify.desktop` → `/usr/share/applications/spotify.desktop` and `~/.local/share/applications/spotify.desktop`
- key `/etc/apt/keyrings/spotify.gpg` · list `/etc/apt/sources.list.d/spotify.list`
- quality: `config/spotify/prefs.high-quality` → `~/.config/spotify/Users/<id>-user/prefs`

## Execute (script)

```bash
./scripts/install-spotify.sh
spotify &
```

## Execute (manual)

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
# backup vendor desktop if present
sudo cp -a /usr/share/applications/spotify.desktop \
  /usr/share/applications/spotify.desktop.bak.chg009.$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
sudo install -m 644 config/desktop/spotify.desktop /usr/share/applications/spotify.desktop
install -m 644 config/desktop/spotify.desktop ~/.local/share/applications/spotify.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true

spotify &
```

Seed: **spotify-client 1:1.2.95.453.g0eeebbed**. Pulse sink on apply: `alsa_output.pci-0000_00_08.0.stereo-fallback`.

## Config

Wrapper (`config/bin/spotify-crostini`) execs `/usr/bin/spotify` with:

`--ozone-platform=x11 --disable-gpu --disable-gpu-compositing --disable-dev-shm-usage --no-sandbox --audio-api=pulseaudio`

and unsets `WAYLAND_DISPLAY`.

Desktop `Exec=/usr/local/bin/spotify-crostini %U`.

Very High pin (`config/spotify/prefs.high-quality`) merged into `~/.config/spotify/Users/*/prefs` after sign-in:

```
audio.play_bitrate_non_metered_migrated=true
audio.sync_bitrate_enumeration=4
audio.play_bitrate_enumeration=4
audio.play_bitrate_non_metered_enumeration=4
```

GUI equivalent: **Settings → Audio Quality → Very high**. Free accounts cap below 4. Re-run `./scripts/install-spotify.sh` if prefs did not exist yet.

## Verify

```bash
test -x /usr/bin/spotify
test -x /usr/local/bin/spotify-crostini
test -f /usr/share/applications/spotify.desktop
test -f ~/.local/share/applications/spotify.desktop
grep -q spotify-crostini /usr/share/applications/spotify.desktop
dpkg-query -W spotify-client
pactl get-default-sink
grep -E '^audio\.(play|sync)_bitrate' ~/.config/spotify/Users/*/prefs
spotify &
pgrep -a spotify
```

Launcher: Chrome OS → **Linux apps** → **Spotify**. If files exist but the folder is empty: **Settings → Developers → Linux → Restart**.

Window must appear (not blank). Sign in in the GUI. One track is the human audio check.

## Backout

```bash
sudo apt-get remove --purge -y spotify-client
sudo rm -f /etc/apt/sources.list.d/spotify.list /etc/apt/keyrings/spotify.gpg
sudo rm -f /usr/local/bin/spotify /usr/local/bin/spotify-crostini
sudo rm -f /usr/share/applications/spotify.desktop
rm -f ~/.local/share/applications/spotify.desktop
sudo apt-get update
rm -rf ~/.config/spotify ~/.cache/spotify
```
