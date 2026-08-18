# CHG-013 — Cloudflare personal DNS (WARP blocked · Families DoH)

> Applied · 2026-08-18 · `penguin` · Med  
> Seed: **dnscrypt-proxy 2.1.8+ds1-1+b4** · live server **cloudflare-family** (1.1.1.3, DoH, ~17 ms)  
> README: [CHG-013](../README.md#chg-013--cloudflare-personal-dns) · Scripts: `scripts/install-cf-dns.sh`, `scripts/install-warp.sh` (alias), optional `scripts/install-cf-ca.sh`  
> Upstream: [1.1.1.1 for Families](https://developers.cloudflare.com/1.1.1.1/1.1.1.1-for-families/) · [WARP Linux](https://developers.cloudflare.com/warp-client/get-started/linux/) (attempted) · [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy)

This chapter is the long form. The README entry is the short rebuild card.

This chapter is **DNS only**. It is not a browser chapter. Chromium is **CHG-014**.

---

## 1 · What we were solving

Hotel / public Wi‑Fi hands out a resolver that can log, hijack, or inject DNS. Penguin does not have its own upstream. Stock:

```text
/etc/resolv.conf → /run/resolv.conf
nameserver 172.20.0.1    # maitred / Chrome OS DNS proxy → hotel DHCP
```

Ask: **Cloudflare WARP, personal free edition**, for DNS security, applied on a Flex Crostini guest (`penguin`, Debian 13).

Scope:

| In | Out |
|----|-----|
| Penguin Linux DNS (Alacritty, apt, git, Island as a Linux app) | Chrome OS host Chrome (Settings → Use secure DNS) |
| Personal consumer 1.1.1.1 / Families | Cloudflare One / Teams / Zero Trust enroll |
| Encrypted DNS (DoH) | Full traffic tunnel through a personal WARP edge |

Plaintext `nameserver 1.1.1.1` (or `.2` / `.3`) on hotel DHCP is **not** enough. The venue can still intercept UDP/53.

---

## 2 · First idea: official WARP (consumer)

Debian 13 (trixie) is a supported Cloudflare apt suite. Consumer path (not Teams):

```bash
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
  | sudo gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ trixie main" \
  | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt-get update && sudo apt-get install -y cloudflare-warp
# never: warp-cli registration organization <work>
warp-cli --accept-tos registration new
warp-cli mode doh
warp-cli dns families malware
warp-cli connect
```

Tried on seed: **cloudflare-warp 2026.6.880.0**. `warp-svc` starts. `/dev/net/tun` exists. systemd is fine. `sudo` does not help: the unit already runs as root.

`warp-svc` never creates `/run/cloudflare-warp/warp_service`. `warp-cli status`:

```text
Unable to connect to the CloudflareWARP daemon: No such file or directory (os error 2)
```

strace: after link/addr/route dumps it sends **RTM_GETRULE** (`nlmsg_type 0x22`). The Crostini guest kernel answers **EOPNOTSUPP**. The daemon blocks on netlink recv and never binds the IPC socket.

```bash
ip rule list
# RTNETLINK answers: Operation not supported
```

Even if the daemon started, full `warp+doh` would be the wrong default: Crostini’s only path to the host is `100.115.92.0/30` plus `172.20.0.0/16`. Consumer WARP has no split-tunnel exclude for those.

The package was **purged** so a hung `warp-svc` does not sit on ~57 MiB.

Crostini also has a standing **system D-Bus** cap: `maitred` holds **256** root connections (`max_connections_per_user`). Apt may print `LimitsExceeded` for UID 0. That is noisy; it is not why `warp-svc` hung.

Retry only after a Chrome OS guest kernel that implements `ip rule`. Do not enroll Teams.

---

## 3 · Decision: Families over DoH (1.1.1.3)

Same personal goal, a client that runs here:

| Address | dnscrypt-proxy name | Blocks |
|---------|---------------------|--------|
| 1.1.1.1 | `cloudflare` | nothing extra |
| 1.1.1.2 | `cloudflare-security` | malware |
| **1.1.1.3** | **`cloudflare-family`** | **malware + adult** |

First pin was `cloudflare-security` (1.1.1.2). Operator chose **1.1.1.3**. Applied:

- Debian **`dnscrypt-proxy`** (DoH, not DNSCrypt-only).
- Resolver **`cloudflare-family`** → `https://family.cloudflare-dns.com/dns-query`.
- Listen **127.0.2.1:53** (Debian socket unit).
- `/etc/resolv.conf` is a **regular file** → `127.0.2.1`. Do not `tee` through the old symlink (that overwrites `/run/resolv.conf`; maitred will clobber it).

DoH on **443** survives hotels that block DoT/853. `ipv6_servers = false`. `require_nolog = true` (Cloudflare’s public policy still applies).

`cdn-cgi/trace` showing `warp=off` is correct. This is not a WARP tunnel.

---

## 4 · What this does *not* cover

| Surface | Why |
|---------|-----|
| Chrome OS host Chrome | Separate resolver. Settings → **Privacy and security → Use secure DNS**. For Families 1.1.1.3 on the host, custom DoH: `https://family.cloudflare-dns.com/dns-query`. |
| Hotel captive portal | Needs the hotel resolver. `cf-dns-crostini off`, complete portal in **Chrome OS Chrome**, then `on`. |
| Island identity | Unchanged. No personal vault / WARP org in Island. |
| Traffic tunnel | No MASQUE/WireGuard. |
| A Linux browser | **CHG-014** (Chromium). Do not mix. |

---

## 5 · Paths

- apt `dnscrypt-proxy` → `/usr/sbin/dnscrypt-proxy`
- `config/dnscrypt/dnscrypt-proxy.toml` → `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`
- `config/dnscrypt/resolv.conf` → `/usr/local/share/crostini/dnscrypt/resolv.conf` and live `/etc/resolv.conf`
- `config/bin/cf-dns-crostini` → `/usr/local/bin/cf-dns-crostini`
- `config/systemd/crostini-cf-dns.service` → `/etc/systemd/system/crostini-cf-dns.service`
- Debian units: `dnscrypt-proxy.socket` (127.0.2.1:53), `dnscrypt-proxy.service`
- optional: `scripts/install-cf-ca.sh`
- backups: `*.bak.chg013.<YYYYMMDD-HHMMSS>`

`scripts/install-warp.sh` execs `install-cf-dns.sh`.

---

## 6 · Execute

```bash
./scripts/install-cf-dns.sh
cf-dns-crostini status
```

Hotel:

```bash
cf-dns-crostini off    # /etc/resolv.conf → /run/resolv.conf (172.20.0.1)
# complete portal in Chrome OS Chrome
cf-dns-crostini on
```

---

## 7 · Verify

```bash
dpkg-query -W dnscrypt-proxy
systemctl is-active dnscrypt-proxy.socket dnscrypt-proxy.service
ss -lun | grep 127.0.2.1:53
test -f /etc/resolv.conf && test ! -L /etc/resolv.conf
grep -F 'nameserver 127.0.2.1' /etc/resolv.conf
grep -F "cloudflare-family" /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo journalctl -u dnscrypt-proxy -n 20 --no-pager
# want: [cloudflare-family] OK (DoH)
getent ahostsv4 cloudflare.com
```

Seed (2026-08-18):

```text
[cloudflare-family] OK (DoH) - rtt: 17ms
dnscrypt-proxy is ready - live servers: 1
```

---

## 8 · Optional Gateway CA (not applied)

Not required for this DoH pin. Only if a later inspect path must be trusted.

TLS inspection needs a **current, per-account** PEM from Zero Trust → Certificates. The public `Cloudflare_CA.pem` expired **2025-02-02** and is refused.

```bash
./scripts/install-cf-ca.sh /path/to/certificate.pem
```

Writes `/usr/local/share/ca-certificates/cloudflare-gateway.crt` and imports NSS (`~/.pki/nssdb`). Do not enroll a work Teams org. Do not file this under CHG-014.

---

## 9 · Backout

```bash
cf-dns-crostini off
sudo systemctl disable --now crostini-cf-dns.service dnscrypt-proxy.service dnscrypt-proxy.socket
sudo apt-get remove --purge -y dnscrypt-proxy
sudo rm -f /usr/local/bin/cf-dns-crostini \
  /etc/systemd/system/crostini-cf-dns.service
sudo rm -rf /usr/local/share/crostini/dnscrypt
sudo systemctl daemon-reload
```

Restore `/etc/resolv.conf.bak.chg013.*` if needed.
