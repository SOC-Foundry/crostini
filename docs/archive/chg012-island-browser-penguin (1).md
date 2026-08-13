# CHG-012 — Island browser on penguin (Crostini)

> `12` · **Applied** · 2026-08-12 · `penguin` (Chrome OS Flex · Crostini Debian 13) · Low–Med  
> Home: paste block into [README Changelog](../README.md#changelog) when merging · host is **not** `p3oos` / `83te`  
> Related: [penguin session summary](penguin-crostini-grok-build-session.md) (CHG-002 / CHG-003 port)

---

## Summary

Installed **Island** (enterprise Chromium browser) into the Crostini Linux container from a local `.deb`, so Linux apps can open a full browser without leaving penguin. No special GPU flags were required on this Flex box — Island launched cleanly under sommelier/Wayland.

This is a **penguin / Crostini** change. It does not touch Hyprland, WirePlumber, or Omarchy system trees. Safe user-space package install only.

---

## Host context

| | |
|---|---|
| Hardware | Dell Latitude 7200 · Chrome OS Flex |
| Container | `penguin` · Debian GNU/Linux 13 (trixie) · amd64 |
| Disk (at apply) | 10 GiB btrfs VM root · ~7 GiB free after install |
| Package | `island-browser-stable` **151.1.97.29-1** |
| Source | Local deb (Chrome OS **My files → Downloads**, then copied into Linux) |

---

## Objective · Challenge · Paths

| | |
|---|---|
| **Objective** | Install Island stable from the vendor `.deb` into Crostini; launch from Chrome OS Linux apps / CLI. |
| **Challenge** | Chrome OS **My files** is not mounted in penguin by default — the `.deb` must be shared or copied into Linux files first. Browser unpack is large (~600 MiB installed); small Crostini disks need headroom. GPU/DRM warnings are common under Crostini but often non-blocking. |
| **Paths** | Local deb (staging) · `/usr/bin/island-browser` · `/opt/island/` · `/usr/share/applications/island-browser.desktop` |

**Staging path used this session**

```text
~/projects/sf/omarchy/island-browser-stable_151.1.97.29-1_amd64.deb
```

(Deb is not required after install; safe to delete to reclaim ~200 MiB.)

---

## Execute

### 0) Get the `.deb` into penguin

Chrome OS Files app — pick one:

1. **Drag** `island-browser-stable_*_amd64.deb` from **My files → Downloads** into **Linux files**, or  
2. Right-click **Downloads** → **Share with Linux**, then use  
   `/mnt/chromeos/MyFiles/Downloads/island-browser-stable_*_amd64.deb`

Confirm from penguin:

```bash
ls -lh ~/projects/sf/omarchy/island-browser-stable_*_amd64.deb
# or: ls -lh /mnt/chromeos/MyFiles/Downloads/island-browser-stable_*_amd64.deb
df -h /   # need ~700+ MiB free for unpack + deps
```

### 1) Install

```bash
export DEBIAN_FRONTEND=noninteractive
DEB="$HOME/projects/sf/omarchy/island-browser-stable_151.1.97.29-1_amd64.deb"
# adjust path if you left the file in Downloads share or home

sudo apt-get install -y "$DEB"
# apt resolves Depends (fonts-liberation, libnss3, …) better than bare dpkg -i
```

If dependencies fail mid-way:

```bash
sudo apt-get install -f -y
```

### 2) Verify

```bash
dpkg -l island-browser-stable
island-browser --version
# expect: Island 151.1.97.29 stable  (version may differ)

command -v island-browser island-browser-stable
ls /usr/share/applications/island-browser.desktop
```

### 3) Launch

- Chrome OS **Launcher** → search **Island**, or  
- Terminal: `island-browser &`

**This host:** no extra CLI flags required. Window opened normally.

**Fallback only if blank/crash on another device:**

```bash
island-browser --disable-gpu &
```

---

## Verify checklist

- [x] `dpkg -l island-browser-stable` shows `ii` / installed  
- [x] `island-browser --version` prints Island stable version  
- [x] Desktop entry present (`island-browser.desktop`)  
- [x] Launcher shows **Island** under Linux apps  
- [x] GUI opens without custom flags (Latitude 7200 Flex / penguin)  
- [x] Disk still healthy (`df -h /` — this box ~27% after install)

---

## Backout

```bash
sudo apt-get remove --purge -y island-browser-stable
sudo apt-get autoremove -y

# optional: remove staged deb
rm -f ~/projects/sf/omarchy/island-browser-stable_*_amd64.deb
# or shared path:
# rm -f /mnt/chromeos/MyFiles/Downloads/island-browser-stable_*_amd64.deb
```

User profile data (if any under `~/.config` / `~/.config/island*`) may remain — remove only if you want a full wipe:

```bash
# inspect first
ls -d ~/.config/*sland* ~/.config/island* 2>/dev/null
```

---

## Package facts (applied)

| Field | Value |
|-------|--------|
| Package | `island-browser-stable` |
| Version | `151.1.97.29-1` |
| Arch | `amd64` |
| Provides | `www-browser` |
| Binary | `/usr/bin/island-browser` → `island-browser-stable` |
| Install root | `/opt/island/island-browser/` (typical Chromium layout) |
| Desktop | `/usr/share/applications/island-browser.desktop` · `org.island.Island.desktop` |
| Deb size | ~201 MiB |
| Installed size (dpkg) | ~600 MiB (+ small deps) |

**Depends (resolved via apt on trixie):** includes `ca-certificates`, `fonts-liberation`, `libnss3`, GTK3/4, GBM, Vulkan loader, ALSA, etc. Exact names may gain `t64` suffixes on newer Debian; let apt resolve them.

---

## Notes · failure modes

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| `No such file` on deb path | Downloads not shared / not copied into Linux | Drag into **Linux files** or Share with Linux |
| `dpkg: dependency problems` | Used `dpkg -i` alone | `sudo apt-get install -y ./file.deb` then `apt-get install -f` |
| `No space left on device` | Default ~10 GiB Crostini disk | Chrome OS **Settings → Developers → Linux** → resize disk; delete staged deb |
| DRM / `drmGetDevices2` log noise | Crostini has no full DRM node | Often harmless; try `--disable-gpu` only if UI fails |
| `DevTools remote debugging is disallowed` | Enterprise policy in build | Expected on managed Island; ignore for daily browse |
| Blank window / crash on open | GPU path flaky in VM | `island-browser --disable-gpu` |
| Not in Chrome OS launcher | Desktop DB not refreshed | Log out/in, or restart Linux from Settings |

**Security / policy:** Island is an **enterprise** browser. Builds may enforce org policies, disable DevTools, or expect MDM. This CHG only covers local `.deb` install on a personal Flex Crostini — not admin enrollment.

**Non-goals:** do not install Island on bare Omarchy/Arch hosts with this procedure (`yay`/AUR paths differ). Do not place the `.deb` permanently in the git tree if the repo is public (binary bloat + license); keep deb out of commits (`.gitignore`).

---

## README paste block (ledger)

Copy into `README.md` Changelog + body when you assign this as the next free CHG on the crostini/omarchy ledger:

```markdown
## CHG-012 — Island browser on penguin

> `12` · Applied · 2026-08-12 · `penguin` · Low–Med  
> Detail: `docs/chg012-island-browser-penguin.md`

| | |
|---|---|
| **Objective** | Install Island stable from vendor `.deb` in Crostini; launch from Linux apps. |
| **Challenge** | My files not visible in penguin until share/copy; ~600 MiB installed size on small VM disk. |
| **Paths** | staged `*.deb` · `/usr/bin/island-browser` · `/usr/share/applications/island-browser.desktop` |

**Execute**

```bash
# after deb is in Linux files, e.g.:
sudo apt-get install -y ~/projects/sf/omarchy/island-browser-stable_151.1.97.29-1_amd64.deb
island-browser --version
island-browser &
```

**Backout**

```bash
sudo apt-get remove --purge -y island-browser-stable
sudo apt-get autoremove -y
```
```

**Changelog row**

| Applied | CHG | Title | Host | Status | Risk | Surfaces |
|---------|-----|-------|------|--------|------|----------|
| 2026-08-12 | [012](#chg-012--island-browser-on-penguin) | Island browser on penguin | penguin | Applied | Low–Med | apt · Island `.deb` · Linux apps |

---

## Suggested `.gitignore` (if deb still in tree)

```gitignore
# vendor browser packages — do not commit
*.deb
island-browser-stable_*.deb
```

---

<sub>Applied 2026-08-12 on `penguin` · Island 151.1.97.29 stable · no CLI flags required for launch on this Flex host.</sub>
