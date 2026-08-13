# CHG-007 — Disk resize

> Applied · 2026-08-12 · `penguin` · Low  
> README: [CHG-007](../README.md#chg-007--disk-resize) · See also: `disk-and-persistence.md`

## Objective

Grow Crostini virtual disk so browser + IDE + WebKit stacks fit.

## Challenge

Default ~**10 GiB** fills quickly. Resize is a **Chrome OS** control, not an in-VM `fdisk` procedure.

## Paths

- Host: Settings → Developers → Linux → **Disk size**  
- Guest: `/dev/vdb` (btrfs on seed)

## Execute

1. Chrome OS **Settings → Linux development environment → Disk size**.  
2. Set target (seed: **213 GiB**).  
3. Apply; wait for resize.  
4. Confirm in penguin:

```bash
df -h /
# seed: ~213G size, large Avail
```

## Verify

```bash
df -h /
lsblk -f
```

## Backout

n/a for routine use. Shrinking is rarely useful; do not experiment on production VMs without backup.
