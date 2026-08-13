# CHG-004 — WasIstLos (WhatsApp)

> Applied · 2026-08-12 · `penguin` · Low  
> README: [CHG-004](../README.md#chg-004--wasistlos-whatsapp)

## Objective

Desktop WhatsApp via Debian **`wasistlos`** (unofficial WhatsApp Web / WebKit shell).

## Challenge

No official Meta Linux client. Pulls a large WebKit dependency set — prefer after disk headroom (see CHG-007).

## Paths

- package `wasistlos`  
- binary `wasistlos`  
- desktop **WasIstLos**

## Execute

```bash
sudo apt-get install -y wasistlos
wasistlos &
# Phone: WhatsApp → Linked devices → Link a device → scan QR
```

Seed: **wasistlos 1.7.0-2**.

## Verify

Launcher shows **WasIstLos**; QR link succeeds with phone online.

## Backout

```bash
sudo apt-get remove --purge -y wasistlos
sudo apt-get autoremove -y
```
