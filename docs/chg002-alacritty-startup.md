# CHG-002 — Alacritty startup banner

> Applied · 2026-08-12 · `penguin` · Low  
> README: [CHG-002](../README.md#chg-002--alacritty-startup) · Config: `config/alacritty/alacritty.toml`

## Objective

New terminal: one-shot system summary, then interactive fish under `~/projects`.

## Challenge

No compositor Super+Return bind. Launch from Chrome OS **Linux apps**. Landing directory was `~/projects`. **CHG-011** moves it to `~/projects/sf` and adds inxi to the banner.

## Paths

- `~/.config/alacritty/alacritty.toml`  
- packages: `alacritty`, `fastfetch`, `iproute2`, `util-linux`

## Execute

```bash
./scripts/bootstrap.sh
# installs config: uname · ip -4 -br addr · lsblk -f · fastfetch · cd ~/projects · exec fish -l
```

## Verify

Open **Alacritty** from the launcher. Expect banner, then Tide prompt in `~/projects`.

## Backout

```bash
rm -f ~/.config/alacritty/alacritty.toml
# optional: sudo apt-get remove --purge alacritty
```
