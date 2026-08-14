# CHG-010 — inxi hardware probe

> Applied · 2026-08-14 · `penguin` · Low  
> README: [CHG-010](../README.md#chg-010--inxi-hardware-probe)

## Objective

**`inxi -MCzm`** works in penguin (no sudo required): machine + CPU + RAM inside the VM. Host chassis / SSD / battery: crosh `battery_test 1` and `storage_status` — there is no `inxi` on Chrome OS Flex.

## Challenge

Crostini is a VM. Guest DMI is **crosvm / ChromiumOS**, not Dell Latitude 7200. `-C` is the useful line (host CPUID). `lshw` / `hwinfo` see the same virtio PCI — do not install them. Many Crostini users cannot `sudo` (account password locked). On this guest, **`inxi -MC` without sudo is enough**; sudo only unlocks a DMI serial we do not need. Debian Recommends pull `mesa-utils` / `lm-sensors`; install with `--no-install-recommends` (that step still needs a one-time apt sudo, or run from a rootful bootstrap).

## Paths

- packages `inxi`, `dmidecode`
- binary `/usr/bin/inxi`

## Execute

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends inxi dmidecode
inxi -c 0 -MC
```

Also landed in `scripts/bootstrap.sh` (same `--no-install-recommends` line). Not in the Alacritty banner.

## Seed output (2026-08-14)

```text
Machine:
  Type: N/A System: ChromiumOS product: crosvm v: N/A serial: N/A
  Mobo: N/A model: N/A serial: N/A BIOS: crosvm v: N/A date: N/A
CPU:
  Info: 8x 1-core model: Intel Core i7-8665U bits: 64 type: SMP cache: L2: 8x 256 KiB (2 MiB)
  Speed (MHz): avg: 2112 min/max: N/A cores: 1: 2112 2: 2112 3: 2112 4: 2112 5: 2112 6: 2112
    7: 2112 8: 2112
```

Richer guest line (`inxi -c 0 -MCzm`): RAM **16 GiB** est. / **14.07 GiB** available. `udevadm` has no DIMM report (expected).

Seed packages: **inxi 3.3.38-1-1** · **dmidecode 3.6-2**.

## Host-side (no apt)

- **Settings → About ChromeOS → Additional details**
- `chrome://system` — `hardware_class`, `meminfo`, `cpuinfo`
- crosh (`Ctrl+Alt+T`): `battery_test 1` · `storage_status`

## Verify

```bash
command -v inxi
dpkg-query -W inxi dmidecode
inxi -c 0 -MC
```

Must print `Machine:` and `CPU:`. Chassis = crosvm is correct. Without sudo, `serial` may read `<superuser required>` — ignore it.

## Backout

```bash
sudo apt-get remove --purge -y inxi
# leave dmidecode
```
