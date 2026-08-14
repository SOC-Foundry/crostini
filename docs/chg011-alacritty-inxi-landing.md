# CHG-011 — Alacritty banner: inxi + land in ~/projects/sf

> Applied · 2026-08-14 · `penguin` · Low  
> README: [CHG-011](../README.md#chg-011--alacritty-banner--projectssf)

## Objective

Alacritty startup still prints `uname` / `ip` / `lsblk` / `fastfetch`, then adds **VM** `inxi -MCzm` and a **HOST** spec block. Interactive fish lands in **`~/projects/sf`** (not `~/projects`, not `/projects/sf`).

## Challenge

There is no `/projects` on Crostini. User asked for `/projects/sf/` — that path is **`$HOME/projects/sf`**. Host Chrome OS has no `inxi`; crosh cannot run from the VM banner. Host block is `~/.config/crostini/host-specs.txt` (Latitude 7200 · Flex + crosh hints).

## Paths

- `config/bin/alacritty-crostini-banner` → `~/.local/bin/alacritty-crostini-banner`
- `config/alacritty/host-specs.txt` → `~/.config/crostini/host-specs.txt`
- `config/alacritty/alacritty.toml` · live `~/.config/alacritty/alacritty.toml`
- landing `~/projects/sf`

## Execute

```bash
./scripts/bootstrap.sh
# or manual:
install -m 755 config/bin/alacritty-crostini-banner ~/.local/bin/alacritty-crostini-banner
mkdir -p ~/.config/crostini ~/projects/sf
install -m 644 config/alacritty/host-specs.txt ~/.config/crostini/host-specs.txt
# set [terminal.shell] program to ~/.local/bin/alacritty-crostini-banner
```

Seed: live toml backed up `~/.config/alacritty/alacritty.toml.bak.chg011.20260814-075146`. Theme left as-is; only the shell program changed.

## Verify

Open **Alacritty**. Expect VM inxi (crosvm + i7-8665U), HOST Latitude block, fastfetch, prompt in `~/projects/sf`.

```bash
test -x ~/.local/bin/alacritty-crostini-banner
grep alacritty-crostini-banner ~/.config/alacritty/alacritty.toml
pwd   # after launch: .../projects/sf
```

## Backout

```bash
cp -a ~/.config/alacritty/alacritty.toml.bak.chg011.* ~/.config/alacritty/alacritty.toml
# or set shell back to fish -c '... cd ~/projects; exec fish -l'
```
