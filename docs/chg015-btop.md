# CHG-015 — btop (guest resource TUI)

> Applied · 2026-08-18 · `penguin` · Low  
> Operator-verified · 2026-08-19 (Linux apps + in-terminal)  
> Seed: **btop 1.3.2-0.1**  
> README: [CHG-015](../README.md#chg-015--btop) · Script: `scripts/install-btop.sh`  
> Upstream: https://github.com/aristocratos/btop

## Objective

**`btop`** in penguin: live CPU / RAM / disk / net / process view of the **guest**. `inxi` (CHG-010) is a one-shot snapshot. This is the interactive TUI. Launch from **Linux apps** in Alacritty, or type `btop` in an existing terminal.

## Challenge

Crostini is a VM. The boxes are **penguin**, not the Latitude 7200:

| Box | What you see | What you do not see |
|-----|----------------|---------------------|
| CPU | 8 vCPUs (seed: i7-8665U) | host package / P-core layout |
| Memory | guest allocation (seed ~14 GiB available) | host Chrome / ARC RAM |
| Disks | virtio `vdb` btrfs `/` | host Flex SSD |
| Net | virtio `eth0` (Chrome OS NAT) | WLAN / captive portal |
| GPU | empty (no DRM) | host iGPU |
| Temps | usually none (`thermal_zone0` is a stub) | host CPU package temp |
| Battery | virtio pack if present | treat crosh `battery_test 1` as source of truth |

Debian also ships `htop`. This chapter is **btop** (in the archive, no extra repo). Vendor `btop.desktop` is `Exec=btop` + `Terminal=true`, which opens **Chrome OS Terminal**, not Alacritty. The kit replaces that desktop with an Alacritty wrapper.

btop 1.3.2 defaults `use_fstab = True`. Penguin has **no `/etc/fstab`**. First launch logged `Mem::collect() : filesystem error … [/etc/fstab]`. The kit config sets `use_fstab = False` and also turns off CPU temp / GPU (no hwmon, no DRM).

Do not install `lm-sensors` / `mesa-utils` hoping for host thermals. Same rule as CHG-010. Do not create a fake `/etc/fstab` for btop.

## Paths

- apt `btop` → `/usr/bin/btop`
- `config/bin/btop-crostini` → `/usr/local/bin/btop-crostini`
- `config/desktop/btop.desktop` → `/usr/share/applications/btop.desktop` and `~/.local/share/applications/btop.desktop`
- `config/btop/btop.conf` → `~/.config/btop/btop.conf`
- backups: `*.bak.chg015.<YYYYMMDD-HHMMSS>`

`/usr/bin/btop` stays the binary. Do not point `PATH` `btop` at the wrapper (that would nest Alacritty when you type `btop` in a terminal).

## Execute

Script:

```bash
./scripts/install-btop.sh
btop
```

Manual:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends btop
sudo install -m 755 config/bin/btop-crostini /usr/local/bin/btop-crostini
sudo cp -a /usr/share/applications/btop.desktop \
  /usr/share/applications/btop.desktop.bak.chg015.$(date +%Y%m%d-%H%M%S)
sudo install -m 644 config/desktop/btop.desktop /usr/share/applications/btop.desktop
mkdir -p ~/.local/share/applications ~/.config/btop
install -m 644 config/desktop/btop.desktop ~/.local/share/applications/btop.desktop
install -m 644 config/btop/btop.conf ~/.config/btop/btop.conf
```

In a terminal: `btop`. From Chrome OS: **Linux apps → btop**.

`apt upgrade` of `btop` may restore the vendor desktop. Re-run the script if `Exec=` is no longer `btop-crostini`.

## Verify

```bash
dpkg-query -W btop
btop --version
test -x /usr/local/bin/btop-crostini
grep -q btop-crostini /usr/share/applications/btop.desktop
grep -q 'use_fstab = False' ~/.config/btop/btop.conf
```

Launcher: **Linux apps → btop** opens Alacritty titled `btop`. Quit with `q`.

## Backout

```bash
sudo apt-get remove --purge -y btop
sudo rm -f /usr/local/bin/btop-crostini
sudo rm -f /usr/share/applications/btop.desktop
rm -f ~/.local/share/applications/btop.desktop
# optional: restore btop.desktop.bak.chg015.* if you removed the package but want the vendor file
# optional: restore ~/.config/btop/btop.conf.bak.chg015.*
# optional: rm -rf ~/.config/btop
```
