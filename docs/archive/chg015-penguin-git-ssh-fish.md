# CHG-015 — Git SSH keys on Crostini (fish)

> `15` · **Applied** · 2026-08-13 · `penguin` (Chrome OS Flex · Crostini Debian 13) · Low  
> Related: [CHG-002 fish/Tide](../README.md) · [CHG-013 permanent Grok](chg013-014-penguin-grok-permanent-and-antigravity.md) · kit sibling: `~/projects/sf/crostini`

---

## Summary

Generated an **ed25519** SSH key for GitHub on Crostini, loaded it with **fish-compatible** `ssh-agent` commands (not bash `eval "$(…)"`), accepted the GitHub host key, and cloned **`git@github.com:SOC-Foundry/crostini.git`** into `~/projects/sf/crostini`.

This is a **user-space** crypto/identity change under `~/.ssh` only. No Omarchy system trees.

---

## Objective · Challenge · Paths

| | |
|---|---|
| **Objective** | Passwordless `git@github.com` over SSH from fish on penguin; clone SOC-Foundry repos. |
| **Challenge** | Bash tutorials break on fish (`eval "$(ssh-agent -s)"` → *Unsupported use of `=`*). Agent does not survive new shells unless re-added or hooked in `conf.d`. First connect to GitHub needs host key trust. |
| **Paths** | `~/.ssh/id_ed25519` · `~/.ssh/id_ed25519.pub` · `~/.ssh/known_hosts` · `~/projects/sf/crostini` |

---

## Applied identity (this host)

| Field | Value |
|-------|--------|
| Key type | ed25519 |
| Comment | `kylejeromethompson@gmail.com` |
| Private key | `~/.ssh/id_ed25519` (mode `600`, never commit) |
| Public key | `~/.ssh/id_ed25519.pub` |
| Fingerprint | `SHA256:PE7nvUBgkCtmlxO0K5JVWlVlspGz2ZZKi9Mxqscw4vE` |
| GitHub host | `github.com` ED25519 · `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` (pinned in `known_hosts`) |
| First SSH clone | `~/projects/sf/crostini` ← `git@github.com:SOC-Foundry/crostini.git` |

Public key (add to GitHub → **Settings → SSH and GPG keys** if not already):

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOH91sAmSfYmKcuOfifOIBxMkZoxoEpsl6J6h8jabIqv kylejeromethompson@gmail.com
```

---

## Execute

### 1) Generate key (fish or bash)

```fish
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "kylejeromethompson@gmail.com"
# defaults: ~/.ssh/id_ed25519  (+ passphrase recommended)
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### 2) Start agent — **fish, not bash**

**Wrong (bash-only; fails in fish):**

```fish
eval "$(ssh-agent -s)"
# fish: Unsupported use of '='. …
```

**Right (fish):**

```fish
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
ssh-add -l
# expect: fingerprint line for id_ed25519
```

`ssh-agent -c` emits fish `set` commands; `ssh-agent -s` emits bash `VAR=value` exports.

### 3) Register public key on GitHub

```fish
cat ~/.ssh/id_ed25519.pub
# copy → https://github.com/settings/keys → New SSH key
```

Optional one-shot clipboard on Crostini (if `xsel`/`wl-copy` available):

```fish
cat ~/.ssh/id_ed25519.pub | xsel -ib   # or: wl-copy
```

### 4) First connect + clone

```fish
cd ~/projects/sf
# empty target dir only — do not clone into non-empty "."
git clone git@github.com:SOC-Foundry/crostini.git
# first time: confirm github.com host key (yes)
# fingerprint should match GitHub’s published ED25519 key
```

**Session pitfall:** `git clone … .` fails if the directory already exists and is non-empty (`mkdir crostini` then clone into `.` without `cd crostini` is easy to botch). Prefer:

```fish
git clone git@github.com:SOC-Foundry/crostini.git crostini
# or: mkdir crostini && cd crostini && git clone git@github.com:SOC-Foundry/crostini.git .
```

### 5) Verify

```fish
ssh -T git@github.com
# Hi <user>! You've successfully authenticated…

cd ~/projects/sf/crostini
git remote -v
# origin  git@github.com:SOC-Foundry/crostini.git (fetch/push)
git status
```

---

## Recommended: durable agent on fish login (optional but useful)

After reboot, `ssh-add -l` may show *The agent has no identities* until you re-`eval` + `ssh-add`. To auto-start a per-user agent once and re-add the key:

```fish
# ~/.config/fish/conf.d/ssh-agent.fish
if status is-interactive
    set -l agent_env $HOME/.ssh/ssh-agent.fish.env
    if test -f $agent_env
        source $agent_env >/dev/null 2>&1
    end
    if not set -q SSH_AUTH_SOCK; or not test -S $SSH_AUTH_SOCK
        ssh-agent -c | sed 's/^echo/#echo/' > $agent_env
        source $agent_env
    end
    # load default key if agent empty (will prompt for passphrase if set)
    if ssh-add -l 2>/dev/null | string match -q '*no identities*'
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
    end
end
```

**Note:** If the key has a passphrase, first interactive shell of the session may prompt once. Empty passphrase skips the prompt (less secure).

Alternative: **1Password / Chrome OS OS keystore** — out of scope for this CHG.

---

## Git identity (if not already set)

SSH auth ≠ commit author. One-time:

```fish
git config --global user.name "Kyle Thompson"
git config --global user.email "kylejeromethompson@gmail.com"
git config --global init.defaultBranch main
```

(Adjust name if your GitHub display name differs.)

---

## Backout

```fish
# remove GitHub key in browser first (Settings → SSH keys), then:
ssh-add -d ~/.ssh/id_ed25519 2>/dev/null
rm -f ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
# keep known_hosts unless you want a full reset:
# rm -f ~/.ssh/known_hosts
rm -f ~/.config/fish/conf.d/ssh-agent.fish ~/.ssh/ssh-agent.fish.env
# optional: remove local clone
# rm -rf ~/projects/sf/crostini
```

---

## Notes · failure modes

| Symptom | Cause | Fix |
|---------|--------|-----|
| `Unsupported use of '='` | Bash `eval "$(ssh-agent -s)"` in fish | `eval (ssh-agent -c)` |
| `Permission denied (publickey)` | Pubkey not on GitHub / wrong key / agent empty | `ssh-add -l`; re-add; check GitHub keys |
| `destination path '.' already exists` | Clone into non-empty cwd | Clone into new dir or empty it first |
| Host authenticity prompt every machine | New `known_hosts` | Accept once; fingerprint `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU` for github.com ED25519 |
| Agent empty after new terminal | No conf.d hook | Re-run agent + `ssh-add`, or install optional `ssh-agent.fish` above |
| Key files world-readable | Bad umask / copy | `chmod 700 ~/.ssh; chmod 600 ~/.ssh/id_ed25519` |

**Security:** Never commit `id_ed25519` or paste the private key into chat/repos. Rotate on GitHub if private key leaks.

---

## README paste block

```markdown
## CHG-015 — Git SSH keys on Crostini (fish)

> `15` · Applied · 2026-08-13 · `penguin` · Low  
> Detail: `docs/chg015-penguin-git-ssh-fish.md`

| | |
|---|---|
| **Objective** | ed25519 SSH to GitHub from fish; clone `SOC-Foundry/crostini`. |
| **Challenge** | Fish rejects bash `ssh-agent -s` eval; agent not sticky without conf.d. |
| **Paths** | `~/.ssh/id_ed25519*` · `known_hosts` · `~/projects/sf/crostini` |

**Execute**

```fish
ssh-keygen -t ed25519 -C "kylejeromethompson@gmail.com"
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
# add id_ed25519.pub to GitHub SSH keys
git clone git@github.com:SOC-Foundry/crostini.git ~/projects/sf/crostini
ssh -T git@github.com
```

**Backout**

```fish
ssh-add -d ~/.ssh/id_ed25519 2>/dev/null
rm -f ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```
```

**Changelog row**

| Applied | CHG | Title | Host | Status | Risk | Surfaces |
|---------|-----|-------|------|--------|------|----------|
| 2026-08-13 | [015](#chg-015--git-ssh-keys-on-crostini-fish) | Git SSH keys on Crostini (fish) | penguin | Applied | Low | `~/.ssh` · fish agent · `sf/crostini` |

---

<sub>Applied 2026-08-13 · fingerprint `SHA256:PE7nvUBgkCtmlxO0K5JVWlVlspGz2ZZKi9Mxqscw4vE` · clone `SOC-Foundry/crostini` OK.</sub>
