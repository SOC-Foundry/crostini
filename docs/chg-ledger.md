# CHG ledger (Crostini)

Numbered chapters in the Omarchy spirit: **Objective · Challenge · Paths · Execute · Backout**.

Penguin session IDs (CHG-012 / 013 / 014) are **aliased** to kit numbers so the original write-ups stay searchable.

| ID | Title | Status | Alias | Risk |
|----|-------|--------|-------|------|
| CROS-001 | Disk & persistence reality | done | — | Low |
| CROS-002 | fish + Tide + done | done | omarchy CHG-002 | Low |
| CROS-003 | Alacritty startup banner | done | omarchy CHG-003 | Low |
| CROS-004 | Permanent Grok Build | done | penguin CHG-013 | Low |
| CROS-005 | Nerd Font for Tide | planned | — | Low |
| CROS-006 | Agent-friendly bash escape | done | — | Low |
| CROS-007 | Shared folder workflow | planned | (feeds CROS-008) | Low |
| CROS-008 | Island browser | done | penguin CHG-012 | Low–Med |
| CROS-009 | Antigravity IDE + CLI | done | penguin CHG-014 | Low–Med |

Detail docs: [chg012-island-browser-penguin.md](chg012-island-browser-penguin.md) · [chg013-014-penguin-grok-permanent-and-antigravity.md](chg013-014-penguin-grok-permanent-and-antigravity.md)

---

## CROS-001 — Disk & persistence reality

**Objective:** Users know what survives reboot vs what requires Linux Remove / reinstall; resize before heavy apps.

**Challenge:** Stock ~10 GiB disk; Grok felt ephemeral even though `~/.grok` lived on `/dev/vdb`.

**Execute:** Chrome OS Settings → Developers → Linux → Disk size. Seed host: **10 GiB → 213 GiB**.

**Backout:** n/a (host setting).

---

## CROS-002 — fish + Tide + done

**Objective:** Login shell is fish with Tide v6 Rainbow + done; bash still reachable.

**Challenge:** No yay/AUR; `chsh` needs sudo on Crostini; Rainbow pwd colors hard to read.

**Paths:** `~/.config/fish/`, backup `~/.config/fish.bak.cros002.*`

**Execute:** `./scripts/bootstrap.sh` (packages + fisher + tide + chsh)

**Backout:**

```bash
rm -rf ~/.config/fish
cp -a ~/.config/fish.bak.cros002.<stamp> ~/.config/fish
sudo chsh -s /bin/bash "$USER"
```

---

## CROS-003 — Alacritty startup banner

**Objective:** New terminal shows system summary then interactive fish in `~/projects`.

**Challenge:** No Super+Return; no `/data/Development/Projects`.

**Paths:** `~/.config/alacritty/alacritty.toml`

**Execute:** bootstrap installs config; launch from Chrome OS Linux apps.

**Backout:** `rm -f ~/.config/alacritty/alacritty.toml`

---

## CROS-004 — Permanent Grok Build on Crostini

> `13` · Applied · 2026-08-12 · `penguin` · Low  
> Detail: `docs/chg013-014-penguin-grok-permanent-and-antigravity.md`

| | |
|---|---|
| **Objective** | `grok` survives reboot without re-curl; PATH + recovery hooks. |
| **Challenge** | Fish login + minimal PATH; curl installer felt required every boot. |
| **Paths** | `~/.grok` · `/usr/local/bin/grok` · `/etc/profile.d/grok.sh` · fish conf.d · `ensure-grok` |

**Execute**

```bash
# if missing: curl -fsSL https://x.ai/cli/install.sh | bash
./scripts/install-grok.sh
grok --version
# updates later: grok update   — do not re-curl every reboot
```

**Backout**

```bash
sudo rm -f /usr/local/bin/grok /usr/local/bin/agent
sudo rm -f /etc/profile.d/grok.sh /usr/share/applications/grok-build.desktop
rm -f ~/.config/fish/conf.d/grok.fish ~/.local/bin/ensure-grok
```

---

## CROS-006 — Agent-friendly bash escape

**Objective:** Interactive TTYs get fish; agents can force bash.

**Execute:** `~/.bashrc` handoff unless `CROSTINI_BASH=1` or `OMARCHY_BASH_NO_FISH=1`.

```bash
CROSTINI_BASH=1 bash
```

---

## CROS-008 — Island browser on penguin

> `12` · Applied · 2026-08-12 · `penguin` · Low–Med  
> Detail: `docs/chg012-island-browser-penguin.md`

| | |
|---|---|
| **Objective** | Install Island stable from vendor `.deb` in Crostini; launch from Linux apps. |
| **Challenge** | My files not visible in penguin until share/copy; ~600 MiB installed on small VM disk. |
| **Paths** | staged `*.deb` · `/usr/bin/island-browser` · `/usr/share/applications/island-browser.desktop` |

**Execute**

```bash
# after deb is in Linux files, e.g.:
./scripts/install-island.sh ~/projects/sf/omarchy/island-browser-stable_151.1.97.29-1_amd64.deb
island-browser --version
island-browser &
```

**Backout**

```bash
sudo apt-get remove --purge -y island-browser-stable
sudo apt-get autoremove -y
```

---

## CROS-009 — Antigravity IDE (apt) + CLI + Crostini

> `14` · Applied · 2026-08-12 · `penguin` · Low–Med  
> Detail: `docs/chg013-014-penguin-grok-permanent-and-antigravity.md`  
> Upstream: https://antigravity.google/download/linux

| | |
|---|---|
| **Objective** | Apt-install Antigravity IDE for in-app/apt updates; CLI `agy`; visible UI on Crostini. |
| **Challenge** | Apt is 1.x IDE line; Electron GPU/Wayland fails without DRM in VM. |
| **Paths** | apt `antigravity` · `/usr/share/antigravity` · `antigravity-crostini` · `agy` |

**Execute**

```bash
./scripts/install-antigravity.sh
antigravity &            # wrapper: X11 + disable-gpu + no-sandbox
agy --version
```

**Backout**

```bash
sudo apt-get remove --purge -y antigravity
sudo rm -f /usr/local/bin/antigravity /usr/local/bin/antigravity-crostini
rm -f ~/.local/bin/agy ~/.config/fish/conf.d/antigravity.fish
```
