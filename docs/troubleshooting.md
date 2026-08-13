# Troubleshooting

## chsh: PAM Authentication failure

```text
chsh -s /usr/bin/fish
# → chsh: PAM: Authentication failure
```

```bash
sudo chsh -s /usr/bin/fish "$USER"
```

Passwordless sudo is typical on penguin.

## fish: Unsupported use of '='

Bash agent snippets fail in fish:

```fish
# wrong
eval "$(ssh-agent -s)"
# right
eval (ssh-agent -c)
```

See **CHG-008**.

## agent CLI: command not found

Login shell is fish; bashrc PATH may not apply:

```bash
./scripts/install-grok.sh
ensure-grok
# updates later: grok update   — not curl every reboot
```

## Tide icons are tofu

Powerline fonts fix separators; full icon sets need a Nerd Font in Alacritty (`font.normal.family`). Planned: CHG-009+.

## Alacritty missing from launcher

```bash
alacritty --version
ls /usr/share/applications/Alacritty.desktop
```

Restart Linux from Settings if the desktop DB is stale.

## Island deb not found

Stage via **Linux files** or Share with Linux — My files is not visible by default.

```bash
./scripts/install-island.sh /path/to/island-browser-stable_*.deb
```

## Antigravity: no window / blank UI

GPU process dies without DRM in the VM. Use the kit wrapper:

```bash
./scripts/install-antigravity.sh
antigravity &   # → antigravity-crostini flags
```

## Disk full on ~10 GiB

Resize Linux disk (CHG-007) before Island + Antigravity + WebKit.

## Permission denied (publickey) for GitHub

```fish
ssh-add -l
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com
```

Confirm the public key is on GitHub → Settings → SSH keys.
