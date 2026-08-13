# CHG-003 — Island browser

> Applied · 2026-08-12 · `penguin` · Low–Med  
> README: [CHG-003](../README.md#chg-003--island-browser) · Script: `scripts/install-island.sh`

## Objective

Install **Island** (enterprise Chromium) from a local vendor `.deb` for a full browser inside the VM.

## Challenge

Chrome OS Downloads are outside the VM until **Share with Linux** or drag to **Linux files**. Install footprint ~600 MiB.

## Paths

- staged `island-browser-stable_*_amd64.deb`  
- package `island-browser-stable`  
- `/usr/bin/island-browser`

## Execute

```bash
# stage deb into the VM first
./scripts/install-island.sh /path/to/island-browser-stable_*_amd64.deb
island-browser &
```

Seed version: **151.1.97.29**. No extra GPU flags required on seed Flex host.

## Verify

```bash
island-browser --version
# launcher: Island
```

## Backout

```bash
sudo apt-get remove --purge -y island-browser-stable
sudo apt-get autoremove -y
```
