# CHG-001 — Fish · Tide · done

> Applied · 2026-08-12 · `penguin` · Low  
> README: [CHG-001](../README.md#chg-001--fish--tide--done) · Script: `scripts/bootstrap.sh`

## Objective

Login shell = **fish** with **Tide** (Rainbow) and **done**. Bash remains available for agents and escape hatches.

## Challenge

- Debian `apt` (not AUR).  
- `chsh` often needs `sudo` on Crostini (PAM).  
- Tide Rainbow pwd defaults can be unreadable; set black-on-blue.  
- Interactive bash still starts from some entry points — hand off to fish unless `CROSTINI_BASH=1`.

## Paths

- `~/.config/fish/`  
- login shell (`getent passwd`)  
- `~/.bashrc` (optional handoff)  
- packages: `fish`, `fonts-powerline`, `fonts-noto-color-emoji`

## Execute

```bash
./scripts/bootstrap.sh
# or manual: apt install fish · fisher · tide + done · sudo chsh -s /usr/bin/fish
```

## Verify

```bash
getent passwd "$USER" | cut -d: -f7   # /usr/bin/fish
fish -c 'fisher list'                 # tide · done · fisher
```

## Backout

```bash
rm -rf ~/.config/fish
# restore backup if taken: ~/.config/fish.bak.chg001.*
sudo chsh -s /bin/bash "$USER"
```
