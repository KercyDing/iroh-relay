# iroh-relay

[sculk](https://github.com/KercyDing/sculk) · [简体中文](README.md)

This repository provides prebuilt `iroh-relay` binaries for Linux amd64 and
arm64. They can be used to deploy a self-hosted Relay server for
[sculk](https://github.com/KercyDing/sculk).

## Download

Download the file for your server architecture from the
[latest Release](https://github.com/KercyDing/iroh-relay/releases/latest):

- `iroh-relay-linux-amd64`
- `iroh-relay-linux-arm64`

Install the downloaded binary:

```bash
chmod +x iroh-relay-linux-amd64
sudo install -m 0755 iroh-relay-linux-amd64 /usr/local/bin/iroh-relay
```

On an arm64 server, replace the file name with `iroh-relay-linux-arm64`.

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

After `iroh-relay` starts, it prints its listening URL in the service log.
Configure sculk with that URL:

```bash
sckc relay --url <URL printed by iroh-relay>
```

In the TUI, open the Relay tab, select the self-hosted Relay option, and enter
the URL.

Use an `https://` URL when a domain and TLS reverse proxy are configured. Use
the `http://` URL when running the service directly with `--dev`.
