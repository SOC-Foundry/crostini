# Agents

CLI agent runbook for this repository (**crostini** — functional Linux desktop inside Chrome OS / Flex Crostini).

## Standing order

1. Prefer **README chapters CHG-001…** and `docs/chg00N-*.md` as source of truth.
2. Legacy material is under `docs/archive/` — do not revive old numbering without explicit user request.
3. User-space only: `~/.config/**`, `~/.local/**`, `/usr/local/bin`, apt, this repo. Never touch Chrome OS host partitions.
4. Match surrounding comment style: short, factual, no narrative placeholders.

## Git policy (mandatory)

**Never** run:

- `git add`
- `git commit`
- `git push`

(or equivalent staging / commit / remote publish).

**Allowed:** read-only and inspect commands — e.g. `git status`, `git log`, `git diff`, `git show`, `git branch`, `git remote -v`, `git stash list` (without applying destructive ops unless the user asks).

The human owns all staging, commits, and pushes.

## Session continuity

- Grok sessions are keyed by **working directory**. `grok -c` continues the latest session for the **current cwd**.
- Resume a known UUID with `grok --resume <session-id>`.
- Do not confuse Grok resume with Antigravity `agy --conversation=…`.

## Format for new changes

New work → next free **CHG-00N** · chapter in README style · optional `docs/chg00N-*.md` · backup rule `*.bak.chg00N.<YYYYMMDD-HHMMSS>` before edits to live config.
