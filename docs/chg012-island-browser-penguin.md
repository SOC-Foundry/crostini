# CHG-012 — Island browser on penguin (Crostini)

> `12` · **Applied** · 2026-08-12 · `penguin` · Low–Med  
> Kit chapter: **CROS-008** · host is **not** `p3oos` / `83te`

Installed **Island** (`island-browser-stable` **151.1.97.29-1**) from a local `.deb` so Linux apps have a full browser without leaving penguin. No extra GPU flags were required on this Flex box.

## Objective · Challenge · Paths

| | |
|---|---|
| **Objective** | Install Island stable from the vendor `.deb`; launch from Chrome OS Linux apps / CLI. |
| **Challenge** | My files is not mounted in penguin until shared/copied. Unpack ~600 MiB; 10 GiB disks are tight. |
| **Paths** | staged `*.deb` · `/usr/bin/island-browser` · `/opt/island/` · `island-browser.desktop` |

Staging used this session: `~/projects/sf/omarchy/island-browser-stable_151.1.97.29-1_amd64.deb` (delete after install).

## Execute

1. Drag the `.deb` into **Linux files**, or Share Downloads → `/mnt/chromeos/MyFiles/Downloads/`.
2. `./scripts/install-island.sh /path/to/island-browser-stable_*.deb`
3. `island-browser --version` then `island-browser &` (or launcher → Island).
4. Fallback only if blank: `island-browser --disable-gpu &`

Use `apt-get install -y ./file.deb`, not bare `dpkg -i`.

## Backout

```bash
sudo apt-get remove --purge -y island-browser-stable
sudo apt-get autoremove -y
rm -f ~/projects/sf/omarchy/island-browser-stable_*.deb
```

Do **not** commit vendor `.deb` files. Island is an enterprise build (DevTools may be policy-blocked).
