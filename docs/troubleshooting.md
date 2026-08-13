# Troubleshooting

## chsh: PAM Authentication failure

```text
chsh -s /usr/bin/fish
# → Password: chsh: PAM: Authentication failure
```

Use elevated chsh (passwordless sudo is typical on penguin):

```bash
sudo chsh -s /usr/bin/fish "$USER"
```

## grok: command not found (in fish)

Login shell is fish; bashrc PATH does not apply. CROS-004 hardens this:

```bash
./scripts/install-grok.sh
# or just recovery:
ensure-grok
cat ~/.config/fish/conf.d/grok.fish
source ~/.config/fish/conf.d/grok.fish
```

**Do not** re-run `curl | bash` every reboot. Updates: `grok update`.

Minimal PATH still works after CROS-004:

```bash
env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$HOME" grok --version
```

## Tide icons are tofu / missing

Install a Nerd Font (CROS-005) into `~/.local/share/fonts` and set `font.normal.family` in `alacritty.toml`. Powerline fonts alone fix separators, not full icon sets.

## Alacritty won’t start under Crostini

```bash
alacritty -e true   # should exit 0
echo "DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
```

Launch from the Chrome OS **Linux apps** launcher rather than expecting Hyprland Super+Return.

## Island `.deb` not found

My files is not mounted until shared:

1. Drag the `.deb` into **Linux files**, or
2. Right-click Downloads → **Share with Linux** → `/mnt/chromeos/MyFiles/Downloads/`

```bash
sudo apt-get install -y /path/to/island-browser-stable_*.deb
# not: dpkg -i   (then apt-get install -f if you already did)
```

Need ~700 MiB free. Delete the staged `.deb` after install.

## Island / Antigravity blank or crash

Crostini often logs `drmGetDevices2` noise (no GPU node).

| App | This Flex host | Fallback |
|-----|----------------|----------|
| Island | no flags needed | `island-browser --disable-gpu &` |
| Antigravity | **wrapper required** | `antigravity-crostini` (X11, `--disable-gpu`, `--no-sandbox`) |

If `apt upgrade` overwrites `antigravity.desktop`, re-point `Exec=` at `/usr/local/bin/antigravity-crostini`.

## apt Antigravity looks “old”

The official apt package is the **1.x** VS Code-family IDE (seed: pkg 1.23.2 / app 1.107.0), not the 2.0 hub or IDE 2.1 tarballs. Intended. Update in-app or via apt after first open.

## apt debconf without a TTY

```bash
export DEBIAN_FRONTEND=noninteractive
```

## pkill kills the agent wrapper

Prefer exact name match:

```bash
pgrep -x alacritty
pgrep -x grok
# kill by PID, not pkill -f grok / pkill -f alacritty
```

## Disk full

Resize Linux disk in Chrome OS Settings. Island + Antigravity want a resized disk (seed: 213 GiB).
