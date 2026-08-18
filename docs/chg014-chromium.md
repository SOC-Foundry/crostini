# CHG-014 — Debian Chromium (personal Linux browser · 2 tabs)

> Applied · 2026-08-18 · `penguin` · Low–Med  
> Seed: **chromium 150.0.7871.100-1~deb13u1**  
> README: [CHG-014](../README.md#chg-014--debian-chromium) · Script: `scripts/install-chromium.sh`

This chapter is the long form. The README entry is the short rebuild card.

This chapter is **the personal Linux browser**. It is not a DNS / WARP chapter. Cloudflare DNS is **CHG-013**.

---

## 1 · What we were solving

Three browser worlds already exist. Mixing them is the failure mode.

| Surface | Role |
|---------|------|
| Host Chrome OS Chrome | Personal Google profile (`kylejeromethompson.com`) — git UI, DRM, sync |
| Island | Work only: Workspace, Zoom, Slack |
| Penguin Linux apps | No personal browser yet — VM files, sites that must not go through Island |

Need a **personal** window in **Linux apps**. Priorities stated: **performance** and **functionality** on this Crostini guest (no GPU, ~14 GiB RAM, Island + host Chrome already running).

---

## 2 · Candidates

Inspected on seed Debian 13 (trixie), 2026-08-18. No extra vendor repos.

| Browser | In Debian apt? | Engine | Crostini fit |
|---------|----------------|--------|--------------|
| **Debian `chromium` 150** | Yes (`150.0.7871.100-1~deb13u1`) | Blink | Same family as Island. Software raster is the path that already works here. |
| **Firefox ESR 140** | Yes (`firefox-esr`) | Gecko | Only Firefox in the archive. No `firefox` (rapid release) package. |
| **Mozilla Firefox (non-ESR)** | No | Gecko | Needs Mozilla’s apt. Same sommelier/WebRender tax as ESR. |
| **Opera** | No (`opera-stable` not in Debian) | Blink fork | Vendor repo + extra services (VPN, ads, account). Another Chromium with more RAM. |
| **Google Chrome** | No (needs Google apt) | Blink | Widevine / sync — already on **host** Chrome. Extra repo and a second Google profile in the VM. |
| Brave / Vivaldi / Edge | No / extra repos | Blink forks | Extra processes. Kit also refuses Snap/Flatpak (README §8). |

---

## 3 · Why not Firefox

Firefox was the first suggestion.

1. **No GPU in the guest.** Sommelier advertises Wayland and X. Firefox WebRender on that path is the usual Crostini jank (scrolling, video). Chromium’s software path matches Island on this Flex host.
2. **Debian only ships ESR.** Seed candidate is **140.12.0esr**. Chromium in the same archive is **150**. Functionality lag on the browser we would use every day.
3. **Performance was a stated priority.** On Linux, Chromium still leads Speedometer / JetStream / MotionMark. The gap is worse when everything is software-rasterized.
4. Firefox remains a valid *second engine* later (containers, uBlock). It is the wrong *first* personal Linux browser on this box.

---

## 4 · Why not Opera

Opera is Chromium with a vendor skin and extra daemons.

1. **Not in Debian.** Needs Opera’s apt (or a `.deb` we will not commit). Same tax as Island’s vendor package, for a personal browser we can get from Debian.
2. **Same engine, more RAM.** Blink + Opera’s sidebar / VPN / ad stack. Guest had ~2.3 GiB free of 14 GiB when we measured. A third Chromium-plus-services is the opposite of the 2-tab cap.
3. **No functionality Island or host Chrome lack** that Debian Chromium does not also lack (Widevine still lives on host Chrome).
4. Account gravity toward Opera sync — another identity next to personal Google and Island. Isolation gets worse, not better.

---

## 5 · Decision: Debian Chromium, two tabs

Applied: apt **`chromium` 150** + Crostini wrapper + a hard **two-tab** cap.

- Not Google Chrome. No Widevine, no Google sync. Host Chrome keeps DRM / personal sync.
- Personal only. Do not sign Island into this profile. Do not use Chromium for work SSO.
- **Two tabs, hard.** Guest RAM. A small MV3 extension keeps the two most-recently-used tabs and closes the rest (Ctrl+T, new window, session restore, incognito spanning). Verified over CDP: a third and fourth tab dropped; two remained.

The wrapper execs **`/usr/lib/chromium/chromium`** with `--load-extension` and `--disable-extensions-except` pointed at `/usr/local/share/crostini/chromium-2tab`.

Do **not** launch `/usr/bin/chromium` directly. That Debian launcher sources `/etc/chromium.d/extensions`, adds `--enable-remote-extensions` and an empty `--load-extension`, and **drops the cap**.

`chromium-sandbox` is a Recommends. Installer uses `--no-install-recommends`, so the wrapper passes `--no-sandbox` (same class as Spotify / Antigravity), plus `--disable-dev-shm-usage` and `--password-store=basic`.

`/etc/chromium.d/crostini-2tab` is installed for documentation / anyone who sources `chromium.d`; the **enforced** path is the wrapper.

---

## 6 · Paths

- apt `chromium` · `chromium-common` → `/usr/bin/chromium` (Debian launcher) · `/usr/lib/chromium/chromium` (binary)
- `config/bin/chromium-crostini` → `/usr/local/bin/chromium-crostini` · `/usr/local/bin/chromium`
- `config/desktop/chromium.desktop` → `/usr/share/applications/chromium.desktop` and `~/.local/share/applications/chromium.desktop`
- `config/chromium/2tab/` → `/usr/local/share/crostini/chromium-2tab`
- `config/chromium/chromium.d-crostini-2tab` → `/etc/chromium.d/crostini-2tab`
- profile: `~/.config/chromium/` (do not commit)
- backups: `*.bak.chg014.<YYYYMMDD-HHMMSS>`

---

## 7 · Execute

Script:

```bash
./scripts/install-chromium.sh
chromium &
```

Manual:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends chromium
sudo install -m 755 config/bin/chromium-crostini /usr/local/bin/chromium-crostini
sudo ln -sfn /usr/local/bin/chromium-crostini /usr/local/bin/chromium
sudo mkdir -p /usr/local/share/crostini/chromium-2tab /etc/chromium.d
sudo install -m 644 config/chromium/2tab/manifest.json config/chromium/2tab/background.js \
  /usr/local/share/crostini/chromium-2tab/
sudo install -m 644 config/chromium/chromium.d-crostini-2tab /etc/chromium.d/crostini-2tab
sudo install -m 644 config/desktop/chromium.desktop /usr/share/applications/chromium.desktop
mkdir -p ~/.local/share/applications
install -m 644 config/desktop/chromium.desktop ~/.local/share/applications/chromium.desktop
chromium &
```

---

## 8 · Verify

```bash
dpkg-query -W chromium
test -x /usr/local/bin/chromium-crostini
test -f /usr/local/share/crostini/chromium-2tab/manifest.json
grep -q load-extension /etc/chromium.d/crostini-2tab
grep -q chromium-crostini /usr/share/applications/chromium.desktop
chromium --version
# want: Chromium 150.x  and wrapper → /usr/lib/chromium/chromium
```

Launcher: **Linux apps → Chromium**. If the icon is missing: **Settings → Developers → Linux → Restart**. Close Island if RAM is tight.

---

## 9 · Backout

```bash
sudo apt-get remove --purge -y chromium chromium-common
sudo rm -f /usr/local/bin/chromium /usr/local/bin/chromium-crostini
sudo rm -f /usr/share/applications/chromium.desktop
sudo rm -rf /usr/local/share/crostini/chromium-2tab
sudo rm -f /etc/chromium.d/crostini-2tab
rm -f ~/.local/share/applications/chromium.desktop
# optional: rm -rf ~/.config/chromium ~/.cache/chromium
```
