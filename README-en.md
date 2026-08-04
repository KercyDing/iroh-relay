# iroh-relay

<kbd>[简体中文](README.md)</kbd>

This repository provides prebuilt `iroh-relay` binaries for Linux amd64 and
arm64. They can be used to deploy a self-hosted Relay server for
[sculk](https://github.com/KercyDing/sculk).

## Install

GitHub mirror, recommended:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/KercyDing/iroh-relay/main/script.sh)"
```

CNB mirror:

```bash
bash -c "$(curl -fsSL https://cnb.cool/SeaLantern-studio/iroh-relay/-/git/raw/main/script.sh)"
```

The script detects the architecture, downloads and verifies the binary, installs it, configures and
starts the systemd service, then prints the Relay URL.

## Use

The script creates and starts the systemd service, then prints the Relay URL.
Enter that URL in sculk's self-hosted Relay setting. Allow inbound TCP 3340 in
the cloud security group, server firewall, and NAT router where applicable.

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

### Q: Does the joining player need to configure the self-hosted Relay?

No manual configuration is required. When the host uses a self-hosted Relay,
the generated `sculk://` ticket contains its URL. The joining player only needs
the complete ticket. After changing the Relay, the host should create a new
room and share the new ticket.

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

## License

[Apache License 2.0](LICENSE)
