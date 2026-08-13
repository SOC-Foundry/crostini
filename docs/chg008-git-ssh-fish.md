# CHG-008 — Git SSH on fish

> Applied · 2026-08-13 · `penguin` · Low  
> README: [CHG-008](../README.md#chg-008--git-ssh-on-fish)

## Objective

ed25519 key for GitHub; fish-correct `ssh-agent`; SSH clone of this kit.

## Challenge

Bash tutorials break fish:

```fish
eval "$(ssh-agent -s)"   # Unsupported use of '='
eval (ssh-agent -c)      # correct
```

Agent identities may be empty in a new shell until re-`ssh-add` (optional durable conf.d later).

## Paths

- `~/.ssh/id_ed25519` · `id_ed25519.pub` · `known_hosts`  
- GitHub → Settings → SSH keys  
- clone target e.g. `~/projects/sf/crostini`

## Execute

```fish
ssh-keygen -t ed25519 -C "you@example.com"
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
# paste into GitHub SSH keys
ssh -T git@github.com
git clone git@github.com:SOC-Foundry/crostini.git ~/projects/sf/crostini
```

## Verify

```fish
ssh-add -l
ssh -T git@github.com
git -C ~/projects/sf/crostini remote -v
```

## Backout

```fish
ssh-add -d ~/.ssh/id_ed25519 2>/dev/null
rm -f ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
# remove key from GitHub UI
```

## Security

Never commit the private key. Rotate on GitHub if leaked.
