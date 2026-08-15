# CHG-012 — 1Password desktop + CLI · personal GitHub SSH agent

> Applied · 2026-08-15 · `penguin` · Med  
> Seed: **1password 8.12.32** · **1password-cli 2.39.0** (`op`)  
> README: [CHG-012](../README.md#chg-012--1password-personal-github-ssh-agent) · Script: `scripts/install-1password.sh`  
> Upstream: [SSH get-started](https://developer.1password.com/docs/ssh/get-started/) · [Linux install](https://support.1password.com/install-linux/) · [CLI app integration](https://developer.1password.com/docs/cli/app-integration/) · [Manage SSH keys](https://developer.1password.com/docs/ssh/manage-keys/)

This chapter is the long form. The README entry is the short rebuild card.

## Why a vaulted SSH agent

I work as a Linux application-security engineer. A lot of the contract work I take is the same incident wearing a different company name: an **npm supply-chain compromise**. In every one of those engagements, the story did not start with a clever registry bug. It started with a **GitHub private key on a local disk** — `~/.ssh/id_*` sitting in the clear, or behind a passphrase that never mattered because something on the box could already read the file.

After that, the rest is mechanical. The attacker publishes as the maintainer, ships a malicious version, and the registry does exactly what it is designed to do.

I have never been called to clean up a supply-chain breach at a shop that actually **enforced a vaulted SSH agent** — keys that do not live on disk, signatures that only happen from an unlocked vault. That is not a vendor claim. It is what those incidents have in common by their absence.

This is not “enterprise-only” hygiene. Personal GitHub is how packages, dots, and side projects get published. In 2026 a developer laptop that still keeps `id_ed25519` next to the working tree is leaving the same file on disk the last wave of npm worms went looking for. CHG-008 put that file on penguin. This chapter takes it off.

---

## 1 · What we were solving

CHG-008 left a personal GitHub ed25519 **on the penguin disk**:

| Path | Role |
|------|------|
| `~/.ssh/id_ed25519` (mode 600) | Private key on the Crostini filesystem |
| `~/.ssh/id_ed25519.pub` | Public; already on GitHub |
| Fingerprint | `SHA256:PE7nvUBgkCtmlxO0K5JVWlVlspGz2ZZKi9Mxqscw4vE` |
| GitHub login | `kylejeromethompson` |
| Remote | `git@github.com:SOC-Foundry/crostini.git` |

Crostini already ran `ssh-agent.service` at `SSH_AUTH_SOCK=/run/user/1000/openssh_agent`, but `ssh-add -l` was **empty**. Git still worked because OpenSSH fell back to the file in `~/.ssh/`. The planned “durable OpenSSH `ssh-agent` fish conf.d” would only have made that disk key stickier.

Goal: **private material only in a vault**. `git` / `ssh` to **personal** `github.com` get signatures from an unlocked desktop agent. The public file and `known_hosts` stay.

This GitHub identity is **personal app development only**. Island is **not** in this path.

---

## 2 · First idea: existing Bitwarden account

The first proposal was “install the Bitwarden vault app as CHG-012,” then “use the Bitwarden CLI SSH agent” to hold the GitHub key.

That matched an existing Bitwarden account and a free/OSS preference. We researched it against this kit and Crostini.

### What Bitwarden actually offers

| Channel | Verdict on penguin |
|---------|-------------------|
| Official Linux **desktop `.deb`** | Real vault window. SSH agent is a **desktop** feature (`~/.bitwarden-ssh-agent.sock`) since ~2025.1. |
| **CLI (`bw`)** | Vault item CRUD after unlock. **Not an SSH agent.** Cannot sign `ssh` challenges. |
| Unofficial `bw` → `ssh-add` scripts | Decrypt the key into Crostini’s OpenSSH agent. Defeats “key not on this machine except in the vault.” Out of scope. |
| AppImage | Known fail on Crostini ([bitwarden/clients#4089](https://github.com/bitwarden/clients/issues/4089)). |
| Snap / Flatpak | Kit **non-goal** (README §8). Extra daemons; seed has neither. |
| Official apt repo | **None.** Download redirect → GitHub `Bitwarden-2026.7.0-amd64.deb` (~108 MiB). **No auto-update** ([feature matrix](https://bitwarden.com/help/desktop-app-feature-support/)). |
| Agent key selection | Tries every vault key. OpenSSH’s six-key limit can fail even when the right key is present. |

Inspected (not installed) `Bitwarden-2026.7.0-amd64.deb`: package `bitwarden`, `/opt/Bitwarden/bitwarden`, vendor desktop `Exec=/opt/Bitwarden/bitwarden %U`. Same Electron tax as Spotify/Antigravity: no `/dev/dri`, both `$DISPLAY` and `$WAYLAND_DISPLAY`. Since 2025.11 Bitwarden dropped `--no-sandbox`; Crostini still needs the kit wrapper.

### Why we did not apply Bitwarden

1. **`bw` is not the agent.** The request “Bitwarden CLI SSH agent” is a product that does not exist. Desktop must stay running either way.
2. **Weaker Linux SSH agent** than 1Password: newer, no apt channel, no per-key agent config, “try all keys.”
3. Same Crostini Electron wrapper work either way. The differentiator was the agent, not the window.
4. Isolation would still forbid a Bitwarden **browser extension in Island**.

Bitwarden remains a valid vault. It was the wrong **SSH agent** for this host.

---

## 3 · Decision: 1Password desktop is the agent

1Password’s Linux SSH agent has been GA since 2022. Official Debian apt repo (auto-update). Socket: `~/.1password/agent.sock`. Agent config TOML can pin key order later. Membership required.

Same Crostini tax: **desktop must run**; `op` is not the signer.

Snap/Flatpak 1Password **cannot** run the SSH agent. Apt `.deb` only — same posture as Spotify.

### Isolation (non-negotiable)

Island is work: Google Workspace, Zoom, Slack. All development is the personal Chrome OS / Google profile (`kylejeromethompson.com`). See `AGENTS.md`.

| Do | Do not |
|----|--------|
| 1Password **desktop** + host-scoped `IdentityAgent` | 1Password extension in Island (or any work browser) |
| `Host github.com ssh.github.com` only | `Host *` or global `SSH_AUTH_SOCK=~/.1password/agent.sock` |
| Import the existing personal ed25519 | Put work remotes or work SSO in this vault |
| Sign in inside the 1Password window | Open personal GitHub / vault sign-in in Island |

If work git ever runs on this VM, it must use another `Host` (enterprise hostname, HTTPS, or a non-1Password identity).

`IdentitiesOnly yes` **without** `IdentityFile` would still prefer default `~/.ssh/id_ed25519` while that file existed. Seed uses:

```
Host github.com ssh.github.com
  IdentityAgent ~/.1password/agent.sock
  IdentityFile ~/.ssh/id_ed25519.pub
  IdentitiesOnly yes
```

The **public** file names the agent identity after the private file is gone.

No fish `SSH_AUTH_SOCK` export. No `environment.d` override. Antigravity’s `git` to `github.com` reads `~/.ssh/config`.

---

## 4 · What landed on seed

| Piece | Seed |
|-------|------|
| Desktop | `1password` **8.12.32** (`/opt/1Password/1password`, `/usr/bin/1password` → vendor) |
| Wrapper | `/usr/local/bin/1password-crostini` · `/usr/local/bin/1password` → wrapper |
| CLI | `1password-cli` **2.39.0** (`op`). Item/CLI only. Not the agent. |
| Desktop entry | `/usr/share/applications/1password.desktop` + user copy; vendor backed up `*.bak.chg012.*` |
| SSH snippet | `config/ssh/config.1password` merged at top of `~/.ssh/config` |
| Socket | `~/.1password/agent.sock` after **Settings → Developer → Use the SSH Agent** |
| Item title | `github-personal-ed25519` |
| `gpg-agent-ssh.socket` | **masked** (gnupg came in as a 1Password dep and would otherwise steal SSH) |
| Private file | **shredded** 2026-08-15 after dual verify |
| Pub + known_hosts | Kept |

---

## 5 · Install (app + CLI)

Script (idempotent): `./scripts/install-1password.sh`

Does **not** read `~/.ssh/id_ed25519`. Does **not** set global `SSH_AUTH_SOCK`. Does **not** touch Island.

### Apt (official)

```bash
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --dearmor --yes -o /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' \
  | sudo tee /etc/apt/sources.list.d/1password.list

sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22 \
  /usr/share/debsig/keyrings/AC2D62742012EA22
curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol \
  | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
  | sudo gpg --dearmor --yes -o /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

sudo apt-get update
sudo apt-get install -y 1password 1password-cli
```

Same signing key as upstream: `3FEF9748469ADBE15DA7CA80AC2D62742012EA22`.

### Crostini wrapper

`config/bin/1password-crostini` execs `/usr/bin/1password` or `/opt/1Password/1password` with:

`--ozone-platform=x11 --disable-gpu --disable-gpu-compositing --disable-dev-shm-usage --no-sandbox`

plus `unset WAYLAND_DISPLAY` and `ELECTRON_OZONE_PLATFORM_HINT=x11`.

Without this, the authorize dialog can be blank and `git` hangs (same class as Spotify / Antigravity).

```bash
sudo install -m 755 config/bin/1password-crostini /usr/local/bin/1password-crostini
sudo ln -sfn /usr/local/bin/1password-crostini /usr/local/bin/1password
sudo install -m 644 config/desktop/1password.desktop /usr/share/applications/1password.desktop
```

PATH `/usr/local/bin` beats `/usr/bin`, so `1password` from a terminal is the wrapper.

### SSH merge

Script prepends `config/ssh/config.1password` to `~/.ssh/config` (backup `~/.ssh/config.bak.chg012.<stamp>`). Seed had no prior config.

### Side effect

`apt install 1password` pulled `gnupg` and enabled `gpg-agent-ssh.socket`. Seed:

```bash
systemctl --user mask gpg-agent-ssh.socket
```

Leave Crostini’s `/run/user/1000/openssh_agent` for non-GitHub SSH.

Updates: `sudo apt-get update && sudo apt-get install -y 1password 1password-cli`

---

## 6 · App: Developer settings and `agent.sock`

1. Launch **Linux apps → 1Password** (or `1password &`). Window must be visible, not blank. If the icon is missing: **Settings → Developers → Linux → Restart**.
2. Sign in with a **personal** membership. Not Island.
3. **Settings → Developer → Use the SSH Agent.** Optional: display key names on authorize prompts.
4. Do **not** rely on browser integration for this CHG. Do not install the extension in Island.
5. Wait for the socket:

```bash
test -S ~/.1password/agent.sock
```

6. Confirm scope:

```bash
ssh -G github.com | grep -i identityagent    # ~/.1password/agent.sock
ssh -G example.com | grep -i identityagent   # empty / not 1Password
echo $SSH_AUTH_SOCK                          # still /run/user/1000/openssh_agent
```

7. **`op` (optional).** Settings → Developer → **Integrate with 1Password CLI**. Then `op vault list` prompts via the desktop app. Linux also wants system-auth unlock for that handshake. **`op` still cannot be the SSH agent.** Official docs: `op item create --category ssh` **generates** a new key; **import of an existing key is desktop-only**.

If the window title is `Lock Screen — 1Password`, the vault is locked. Agent socket may still exist; identities will be empty until unlock. Autolock on seed: 60 minutes.

---

## 7 · Import the existing GitHub private key

Do **not** `cat` the private key into a terminal, chat, repo, or `op` argv.

Official UI ([import](https://developer.1password.com/docs/ssh/manage-keys/#import-an-ssh-key)):

1. Record the pub fingerprint first:

```bash
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
# expect: SHA256:PE7nvUBgkCtmlxO0K5JVWlVlspGz2ZZKi9Mxqscw4vE
```

2. Unlock 1Password. **New Item → SSH Key → Add Private Key → Import a Key File** (or paste from a local editor). Pick `~/.ssh/id_ed25519`. Not **Generate**.
3. Title: `github-personal-ed25519`. Save.
4. Confirm the item fingerprint matches the pub.
5. Agent must list it (public only):

```bash
SSH_AUTH_SOCK=$HOME/.1password/agent.sock ssh-add -l
# 256 SHA256:PE7nvUBgkCtmlxO0K5JVWlVlspGz2ZZKi9Mxqscw4vE github-personal-ed25519 (ED25519)
```

Seed used the desktop import path. `op` was installed for later CLI use, not for this import.

---

## 8 · Verify GitHub auth, then shred

Order is mandatory. Do not shred until both auths succeed **with the file still present**, then again **after** shred.

### With the file still present (seed: 2026-08-15)

```bash
ssh -T git@github.com
# Hi kylejeromethompson! You've successfully authenticated, but GitHub does not provide shell access.
# exit 1 is success — GitHub has no shell.

git -C ~/projects/sf/crostini ls-remote --heads origin
# 7efc057…        refs/heads/main
```

Authorize the 1Password prompt if it appears.

### Shred (seed: executed)

```bash
shred -u ~/.ssh/id_ed25519
# keep ~/.ssh/id_ed25519.pub and ~/.ssh/known_hosts
test ! -e ~/.ssh/id_ed25519
```

`shred -u` overwrites then unlinks. Do not commit a backup of the private file.

### After shred (seed: re-verified)

```bash
SSH_AUTH_SOCK=$HOME/.1password/agent.sock ssh-add -l
# same fingerprint, title github-personal-ed25519

ssh -T git@github.com
# Hi kylejeromethompson! …

git -C ~/projects/sf/crostini ls-remote --heads origin
# still succeeds
```

OpenSSH now has **no** private file. It asks 1Password for the identity named by `IdentityFile ~/.ssh/id_ed25519.pub`.

Leave the **GitHub website** key in place. Do not rotate in this CHG.

---

## 9 · How to re-check later

1Password must be **unlocked**.

```bash
test -S ~/.1password/agent.sock; echo socket-$?
SSH_AUTH_SOCK=$HOME/.1password/agent.sock ssh-add -l
ssh -G github.com | grep -i identityagent
ssh -T git@github.com
git -C ~/projects/sf/crostini ls-remote --heads origin
test ! -e ~/.ssh/id_ed25519
```

`./scripts/verify.sh` soft-checks package, wrapper, socket, `IdentityAgent`, and leftover `id_ed25519`.

---

## 10 · Verify (rebuild)

```bash
dpkg-query -W 1password 1password-cli
test -x /usr/local/bin/1password-crostini
test -S "$HOME/.1password/agent.sock"
ssh -G github.com | grep -i identityagent
ssh -T git@github.com
test ! -e "$HOME/.ssh/id_ed25519"
# isolation: SSH_AUTH_SOCK must not be ~/.1password/agent.sock
```

Launcher: Chrome OS → **Linux apps** → **1Password**. Window must appear (not blank).

---

## 11 · Failure modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Error connecting to agent: Connection refused` | Desktop not running / agent toggle off | Launch + Developer → Use the SSH Agent |
| `ssh-add -L` empty, git still worked (pre-shred) | Disk `id_ed25519` fallback | Confirm IdentityAgent; shred only after agent verify |
| `Permission denied (publickey)` after shred | Vault locked or item missing | Unlock; check Developer → View SSH Agent |
| Git hangs | Blank authorize UI | Wrapper flags; restart Linux |
| Antigravity / other host uses 1Password | `Host *` or global `SSH_AUTH_SOCK` | Restore `~/.ssh/config.bak.chg012.*`; re-run install script |
| `op`: connection reset | CLI integration off or app locked | Settings → Developer → Integrate with 1Password CLI; unlock |
| AppImage / Snap / Flatpak | No agent or Crostini fail | Apt only |

---

## 12 · Backout

```bash
# restore ~/.ssh/config.bak.chg012.*
sudo apt-get remove --purge -y 1password 1password-cli
sudo rm -f /etc/apt/sources.list.d/1password.list
sudo rm -f /usr/share/keyrings/1password-archive-keyring.gpg
sudo rm -f /usr/local/bin/1password /usr/local/bin/1password-crostini
sudo rm -f /usr/share/applications/1password.desktop
rm -f ~/.local/share/applications/1password.desktop
systemctl --user unmask gpg-agent-ssh.socket 2>/dev/null || true
sudo apt-get update
# recover private field from the 1Password SSH Key item (Export) if you need a disk key again
```

Crostini `ssh-agent.service` can stay. We never pointed the whole session at 1Password.

---

## 13 · Out of scope

- Bitwarden desktop / `bw` as agent
- Snap / Flatpak / AppImage
- Island, native messaging, host Chrome extension
- Passkeys
- Rotating the GitHub key
- Work git hosts
- Staging / commit / push
