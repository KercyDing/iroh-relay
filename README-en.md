# iroh-relay

<kbd>[简体中文](README.md)</kbd>

This repository provides prebuilt `iroh-relay` binaries for Linux amd64 and
arm64. They can be used to deploy a self-hosted Relay server for
[sculk](https://github.com/KercyDing/sculk).

## Install

### Linux amd64

```bash
curl --fail --location --output /tmp/iroh-relay https://github.com/KercyDing/iroh-relay/releases/latest/download/iroh-relay-linux-amd64
sudo install -m 0755 /tmp/iroh-relay /usr/local/bin/iroh-relay
```

### Linux arm64

```bash
curl --fail --location --output /tmp/iroh-relay https://github.com/KercyDing/iroh-relay/releases/latest/download/iroh-relay-linux-arm64
sudo install -m 0755 /tmp/iroh-relay /usr/local/bin/iroh-relay
```

## systemd service

Create `/etc/systemd/system/iroh-relay.service`:

```ini
[Unit]
Description=Iroh Relay Server (dev mode, plain HTTP)
After=network.target

[Service]
ExecStart=/usr/local/bin/iroh-relay --dev
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now iroh-relay
sudo journalctl -u iroh-relay -f
```

## Configure sculk

In `--dev` mode, the server listens on TCP port 3340 on all interfaces by
default. Form the Relay URL from the server's public IP address or domain:

```text
http://<server-public-ip>:3340
```

Then configure sculk with that URL:

```bash
sckc relay --url http://<server-public-ip>:3340
```

In the TUI, open the Relay tab, select the self-hosted Relay option, and enter
the URL.

Use an `https://` URL when a domain and TLS reverse proxy are configured. Use
the `http://` URL when running the service directly with `--dev`.

## FAQ

### Q: Which ports do `--dev` and regular mode use?

The current systemd example runs `iroh-relay --dev`, which listens on TCP
port 3340 by default. Without `--dev`, the default port is TCP 80. Before
starting in regular mode, check whether port 80 is already in use:

```bash
sudo ss -ltnp 'sport = :80'
```

If the command produces output, identify the process before continuing. A web
server or reverse proxy often already occupies port 80, and another service
cannot bind to the same address and port.

### Q: How do I verify that the service is listening?

Run:

```bash
sudo systemctl status iroh-relay
sudo ss -ltnp 'sport = :3340'
```

A `Local Address` of `*:3340` or `[::]:3340` means that the service is
listening on all interfaces.

### Q: Which IP address should I use?

List local addresses:

```bash
hostname -I
```

Addresses in `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16` are normally
private addresses and cannot be reached directly by players on the internet.
You can query the public IPv4 address seen by an external service:

```bash
curl -4 https://icanhazip.com
```

The resulting URL is normally `http://<public-ipv4>:3340`. If the server is
behind NAT, configure port forwarding on the upstream router as well.

### Q: Why is there no listening URL in the log?

The current `iroh-relay --dev` command does not guarantee that it will print an
externally reachable URL. The systemd message `Started iroh-relay.service` only
means that the process started. Use `ss` to verify the listening port, then
combine the server's public IP address with port 3340.

### Q: Do I need to open a port?

Yes. Allow inbound TCP port 3340 in both the cloud security group and the
server firewall. A process can listen successfully on the server while still
being unreachable from the internet.

### Q: Does the joining player need to configure the self-hosted Relay?

No manual configuration is required. When the host uses a self-hosted Relay,
the generated `sculk://` ticket contains its URL. The joining player only needs
the complete ticket. After changing the Relay, the host should create a new
room and share the new ticket.

### Q: Does sculk fall back to an n0 Relay if the self-hosted Relay is unavailable?

No. sculk may still establish a direct P2P connection. If neither a direct
connection nor the Relay in the ticket is available, the connection retries
and eventually fails. Reconnection after an established connection is lost
does not switch to an n0 Relay either.

### Q: How do I stop the service?

Stop it temporarily:

```bash
sudo systemctl stop iroh-relay
```

Stop it and disable automatic startup:

```bash
sudo systemctl disable --now iroh-relay
```

### Q: Is `--dev` suitable for long-term public deployment?

No. `--dev` uses plain HTTP and is intended primarily for testing. A long-term
deployment should use a domain and TLS, with access controls, monitoring, and
bandwidth limits appropriate for its expected traffic.
