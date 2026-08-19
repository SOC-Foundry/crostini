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

## btop: command not found

```bash
./scripts/install-btop.sh
btop --version
```

## btop from Linux apps opens Chrome OS Terminal

Vendor `btop.desktop` is `Terminal=true`. The kit wrapper must be on `Exec=`:

```bash
grep ^Exec= /usr/share/applications/btop.desktop
# want: Exec=/usr/local/bin/btop-crostini
./scripts/install-btop.sh
```

Then **Settings → Developers → Linux → Restart**. `apt upgrade` of `btop` can restore the vendor file.

## btop GPU / temp empty; battery looks wrong

Expected on penguin. No DRM, no useful hwmon. Host battery: crosh `battery_test 1`. Host chassis: CHG-010 / crosh, not btop. `btop.log` may still say `No good candidate for cpu sensor` even with `check_temp = False` — probe happens at start; ignore it.

## btop.log: filesystem error [/etc/fstab]

Crostini has no `/etc/fstab`. Want `use_fstab = False` in `~/.config/btop/btop.conf`. Re-run `./scripts/install-btop.sh`. Do not invent an fstab.

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

## Hotel / public Wi‑Fi: no Linux DNS, or portal will not load

Complete the captive portal in **Chrome OS Chrome** first. Then:

```bash
cf-dns-crostini off    # penguin uses 172.20.0.1 again
# finish portal if needed
cf-dns-crostini on     # back to Cloudflare DoH
```

Do not expect official `warp-cli connect` to work. See CHG-013.

## warp-cli: Unable to connect to the CloudflareWARP daemon

Expected on this guest. `ip rule list` is `Operation not supported`. `warp-svc` never binds `/run/cloudflare-warp/warp_service`. Use `cf-dns-crostini` (dnscrypt-proxy → `cloudflare-family`, 1.1.1.3). Do not enroll a work Teams org.

## penguin DNS still 172.20.0.1 after install

`/etc/resolv.conf` is still the Crostini symlink. `tee` through that symlink writes `/run/resolv.conf` and maitred will overwrite it.

```bash
ls -l /etc/resolv.conf    # want a regular file, not → /run/resolv.conf
cf-dns-crostini on
```

## dnscrypt-proxy live server is `cloudflare` or `cloudflare-security`, not `cloudflare-family`

Want `server_names = ['cloudflare-family']` (1.1.1.3). Config was replaced while the service was already up, or the first pin was malware-only. Restart after the toml:

```bash
grep server_names /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo systemctl restart dnscrypt-proxy.service
sudo journalctl -u dnscrypt-proxy -n 15 --no-pager
# want: [cloudflare-family] OK (DoH)
```

## apt prints D-Bus LimitsExceeded (UID 0)

Crostini `maitred` holds the system bus `max_connections_per_user` (256) as root. Noisy; packages still install. Not the WARP hang.

## Chromium missing from Linux apps / blank window

Same CEF/DRM class as Spotify. Use the wrapper:

```bash
./scripts/install-chromium.sh
chromium &
grep ^Exec= /usr/share/applications/chromium.desktop
# want: Exec=/usr/local/bin/chromium-crostini %U
```

Personal only. Island stays work. **Two tabs max** (wrapper loads `/usr/local/share/crostini/chromium-2tab`). A third tab is closed; the two most recently used stay. Launch `chromium` / Linux apps — **not** `/usr/bin/chromium` (Debian launcher drops the cap). If the icon is missing: **Settings → Developers → Linux → Restart**.

## Chrome / Island NET::ERR_CERT_AUTHORITY_INVALID with WARP / Gateway

This is **CHG-013**, not the Chromium chapter. Consumer 1.1.1.1 DoH does not need a custom CA. Gateway TLS inspection does.

The public `Cloudflare_CA.pem` **expired 2025-02-02**. Download a current `.pem` from Zero Trust → Certificates, stage it into Linux files, then:

```bash
./scripts/install-cf-ca.sh /path/to/certificate.pem
```

Restart Island. Host Chrome OS is a separate certificate UI.

Do not enroll a work Teams org on penguin. Official `warp-svc` still cannot start here (no `ip rule`).
