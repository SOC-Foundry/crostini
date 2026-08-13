# CHG-005 — Agent CLI permanent install

> Applied · 2026-08-12 · `penguin` · Low  
> README: [CHG-005](../README.md#chg-005--agent-cli-permanent-install) · Scripts: `install-grok.sh`, `ensure-grok`

## Objective

Optional coding **agent CLI** (Grok Build) on the **persistent** Crostini disk so reboot does not require re-curl. Secondary to the desktop thesis — not the focus of this repo.

## Challenge

Install felt ephemeral: PATH incomplete under fish; habit of re-running curl. Binary already lives under `~/.grok` on `/dev/vdb`.

## Paths

- `~/.grok/` (binary, auth, sessions)  
- `/usr/local/bin/grok`  
- `/etc/profile.d/grok.sh`  
- `~/.config/fish/conf.d/grok.fish`  
- `ensure-grok`  
- desktop launcher (optional)

## Execute

```bash
./scripts/install-grok.sh    # curls only if missing
ensure-grok
grok --version
# later: grok update
```

## Verify

```bash
command -v grok
env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$HOME" grok --version
```

## Backout

```bash
sudo rm -f /usr/local/bin/grok /usr/local/bin/agent
sudo rm -f /etc/profile.d/grok.sh /usr/share/applications/grok-build.desktop
rm -f ~/.config/fish/conf.d/grok.fish ~/.local/bin/ensure-grok
# optional: rm -rf ~/.grok
```
