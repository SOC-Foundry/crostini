# Troubleshooting

## chsh: PAM Authentication failure

```text
chsh -s /usr/bin/fish
# → chsh: PAM: Authentication failure
```

```bash
sudo chsh -s /usr/bin/fish "$USER"
```

Passwordless sudo is typical on penguin.

## fish: Unsupported use of '='

Bash agent snippets fail in fish:

```fish
# wrong
eval "$(ssh-agent -s)"
# right
eval (ssh-agent -c)
```

See **CHG-008**.

## agent CLI: command not found

Login shell is fish; bashrc PATH may not apply:

```bash
./scripts/install-grok.sh
ensure-grok
# updates later: grok update   — not curl every reboot
```

## Tide icons are tofu

Powerline fonts fix separators; full icon sets need a Nerd Font in Alacritty (`font.normal.family`). Planned: CHG-011+.

## Alacritty missing from launcher

```bash
alacritty --version
ls /usr/share/applications/Alacritty.desktop
```

Restart Linux from Settings if the desktop DB is stale.

## Island deb not found

Stage via **Linux files** or Share with Linux — My files is not visible by default.

```bash
./scripts/install-island.sh /path/to/island-browser-stable_*.deb
```

## Antigravity: no window / blank UI

GPU process dies without DRM in the VM. Use the kit wrapper:

```bash
./scripts/install-antigravity.sh
antigravity &   # → antigravity-crostini flags
```

## Spotify missing from Linux apps

Garcon only lists a `.desktop` that exists. Confirm:

```bash
ls /usr/share/applications/spotify.desktop ~/.local/share/applications/spotify.desktop
grep ^Exec= /usr/share/applications/spotify.desktop
# want: Exec=/usr/local/bin/spotify-crostini %U
```

Then **Settings → Developers → Linux → Restart**. Same refresh as a missing Alacritty icon.

## Spotify: no window / blank UI

Same CEF/DRM class as Antigravity. Launch the wrapper, not `/usr/bin/spotify` directly:

```bash
./scripts/install-spotify.sh
spotify &   # → /usr/local/bin/spotify-crostini
pgrep -a spotify
```

## Spotify: window up, no sound

Do **not** apt-install `pipewire-audio` or replace Pulse. Seed already has PipeWire-Pulse.

```bash
pactl info
pactl get-default-sink
# expect a real sink, not auto_null
```

Wrapper must pass `--audio-api=pulseaudio`. Chrome OS volume / mute is host-owned.

Very High (~320 kbit/s) is `audio.play_bitrate_enumeration=4` in `~/.config/spotify/Users/*/prefs` (Premium). Re-run `./scripts/install-spotify.sh` after first sign-in, or set **Settings → Audio Quality → Very high**. Do not commit that prefs file.

## inxi: command not found

```bash
sudo apt-get install -y --no-install-recommends inxi dmidecode
inxi -c 0 -MC
```

## sudo asks for a password / I cannot sudo

Crostini login often has a **locked** password (`passwd -S` shows `L`). Interactive `sudo` then fails. The probe does **not** need sudo:

```bash
inxi -MC
```

Apt/bootstrap still need a one-time rootful install. This seed has `/etc/sudoers.d/10-no-password` so some shells can `sudo -n`; do not assume that. Do not set a password unless you choose to.

## inxi serial says superuser required

Expected without sudo. CPU and crosvm product still print. Ignore serial.

## inxi says ChromiumOS / crosvm, not Latitude

Correct. That is the VM chassis. CPU (`-C`) is the real i7-8665U. For SSD / battery / model: **Settings → About ChromeOS**, `chrome://system`, or crosh `storage_status` / `battery_test 1`. Do not install `lshw` for this.

## Disk full on ~10 GiB

Resize Linux disk (CHG-007) before Island + Antigravity + WebKit.

## Permission denied (publickey) for GitHub

CHG-012: 1Password desktop must be running, unlocked, with **Settings → Developer → Use the SSH Agent**. Socket: `~/.1password/agent.sock`.

```fish
test -S ~/.1password/agent.sock
ssh -G github.com | grep -i identityagent
ssh -T git@github.com
```

Authorize the prompt in 1Password. Do not `ssh-add` the disk key. Do not set `SSH_AUTH_SOCK` globally.

If the private file was already deleted and the vault item is missing, recover the private field from 1Password or restore a backup you made yourself.

Confirm the public key is on personal GitHub → Settings → SSH keys.

## 1Password window blank / git hangs

Same as other Electron apps. Use the kit wrapper (`1password-crostini`). Restart Linux if the Linux apps icon is missing.

## 1Password agent answers a non-GitHub host

`~/.ssh/config` must not use `Host *`. Restore `~/.ssh/config.bak.chg012.*` and re-run `./scripts/install-1password.sh`.
