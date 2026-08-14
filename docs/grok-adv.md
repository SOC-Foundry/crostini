# Advocating for Grok in the dev community

Practical advocacy that actually moves other developers — without turning into fanwar noise.

## What works (and what doesn’t)

**Works:** concrete artifacts and “I shipped this on X.”  
**Doesn’t:** “Grok is better than Claude” with no proof.

The best ammo is a public repo, a real Flex laptop, a full desktop stack, and a CHG ledger. That’s stronger than any model scoreboard.

---

## 1. Lead with the work, name the tool second

Share the outcome first:

- “I turned a Latitude 7200 + Chrome OS Flex into a full Linux devshell (fish, Alacritty, Island, Antigravity, SSH) with an agent that only touches user-space and never commits for me.”
- Then: “I did the session with Grok Build.”

People adopt tools that reduce friction. They’re allergic to brand sermons.

---

## 2. Be specific about *where* Grok helped you

Other devs care about modes of work, not vibes. Examples from this project:

| Moment | Why it lands with engineers |
|--------|-----------------------------|
| **Crostini / Flex constraints** | Debugged DRM/Wayland blank IDE, `chsh` PAM, fish `ssh-agent`, 10 GiB → 213 GiB — environment-specific, not generic “write a function” |
| **Runbook discipline** | CHG chapters, backups, backout, archive vs canonical docs — ops mindset |
| **Agent policy** | No `git add`/`commit`/`push` unless you own the repo — trust model |
| **Session handoff** | `--resume` vs `-c` vs cwd-scoped sessions — real multi-day workflow |
| **Idempotent scripts** | Bootstrap, ensure-grok, installers — productizable, not one-off chat paste |

A short post with *one* of those stories beats “Grok > Claude.”

---

## 3. Compare fairly (credibility filter)

If you compare, use dimensions, not worship:

- **Where Claude often wins:** long policy docs, some enterprise workflows, habits people already have in Claude Code / Cursor.
- **Where you found Grok strong:** messy host/VM environments, iterative “install, break, fix, document,” staying inside a ledger/script kit, following hard agent rules.

Admitting tradeoffs makes you sound like a senior engineer, not a shill.

---

## 4. Channels that actually reach devs

| Channel | Format |
|---------|--------|
| **GitHub** | Excellent README + `docs/` (you have this). Pin the repo. Good commit history when *you* commit. |
| **X / Bluesky** | 1–3 screenshots: Alacritty Tide banner, Island, Antigravity on Flex, `df -h` 213G. Thread: problem → constraint → fix. |
| **r/chromeos, r/chrultrabook, r/linuxquestions** | “Flex + Crostini as daily driver for Arch refugees” — practical title. |
| **Hacker News** | Only if the README is the story (“Show HN: Linux desktop runbook for Chrome OS Flex”). Avoid model flamewars on HN. |
| **Internal / Discord / work** | “I have a reproducible penguin setup” — offer to pair for 15 minutes. |

---

## 5. A template you can reuse

> I run Chrome OS Flex on a used Dell and treat Crostini as my real Linux desktop.  
> Over two days I built a public runbook ([repo]) for fish/Tide, Alacritty, Island, WhatsApp (WasIstLos), Antigravity with a Crostini GPU workaround, permanent agent PATH, and Git SSH on fish — all user-space, CHG-style backouts.  
> I used **Grok Build** for the session. What sold me wasn’t a leaderboard; it was staying disciplined on a weird stack (Flex + penguin) and leaving something another operator can re-run.  
> If you dual-boot just for a “real” terminal, try this path first.

Swap in your voice; keep the **artifact link** and **one weird constraint** (DRM, fish agent, Flex).

---

## 6. What *not* to do

- Don’t dunk on Claude users or Anthropic. Converts come from respect.
- Don’t claim “always better.” Say “better *for this*.”
- Don’t hide that Grok (and every agent) still needs review — lean into no auto-commit.
- Don’t spam model comparisons under every AI post.

---

## 7. The meta move

The strongest advocacy is **being the person who ships on odd platforms**. Chrome OS Flex + Crostini is under-served. Own that niche:

**“Arch brain on a Flex box, documented.”**

If people clone the repo and it works, they’ll ask what agent you used. That’s the correct order.

---

<sub>Saved from the penguin crostini kit session · 2026-08-13</sub>
