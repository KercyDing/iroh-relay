# iroh-relay

[sculk](https://github.com/KercyDing/sculk) · [English](README.en.md)

本仓库提供适用于 Linux amd64 和 arm64 的 `iroh-relay` 预编译文件，用于部署
[sculk](https://github.com/KercyDing/sculk) 自建 Relay 服务器。

## 安装

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

## systemd 服务

创建 `/etc/systemd/system/iroh-relay.service`：

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

启用并启动：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now iroh-relay
sudo journalctl -u iroh-relay -f
```

## 在 sculk 中配置

`iroh-relay` 启动后会在日志中打印监听地址，将该地址填入 sculk：

```bash
sckc relay --url <iroh-relay 输出的 URL>
```

使用 TUI 时，进入“中继”标签页，切换到“自建中继”并填入 URL。

若绑定了域名并配置了 TLS 反向代理，填入 `https://` 地址；使用 `--dev`
直接运行时填入 `http://` 地址。
