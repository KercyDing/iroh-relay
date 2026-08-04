# iroh-relay

<kbd>[English](README-en.md)</kbd>

本仓库提供适用于 Linux amd64 和 arm64 的 `iroh-relay` 预编译文件，用于部署
[sculk](https://github.com/KercyDing/sculk) 自建 Relay 服务器。

## 安装

```bash
# CNB 镜像源，推荐
bash -c "$(curl -fsSL https://cnb.cool/SeaLantern-studio/iroh-relay/-/raw/main/script.sh)"
```

```bash
# GitHub 源
bash -c "$(curl -fsSL https://raw.githubusercontent.com/KercyDing/iroh-relay/main/script.sh)"
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

`--dev` 默认监听所有网卡的 TCP 3340 端口。将服务器的公网 IP 或域名组成
Relay URL：

```text
http://<服务器公网 IP>:3340
```

然后将该地址填入 sculk：

```bash
sckc relay --url http://<服务器公网 IP>:3340
```

使用 TUI 时，进入“中继”标签页，切换到“自建中继”并填入 URL。

若绑定了域名并配置了 TLS 反向代理，填入 `https://` 地址；使用 `--dev`
直接运行时填入 `http://` 地址。

## FAQ

### Q: `--dev` 和普通模式分别使用哪个端口？

当前 systemd 示例使用 `iroh-relay --dev`，默认监听 TCP 3340。不带
`--dev` 时默认使用 TCP 80。启动普通模式前，应先检查 80 端口是否已被占用：

```bash
sudo ss -ltnp 'sport = :80'
```

如果命令有输出，请先确认占用进程。Web 服务器或反向代理通常已经使用 80
端口，此时不能再启动另一个监听相同地址和端口的服务。

### Q: 如何确认服务正在监听？

执行：

```bash
sudo systemctl status iroh-relay
sudo ss -ltnp 'sport = :3340'
```

`Local Address` 显示 `*:3340` 或 `[::]:3340` 表示服务正在所有网卡上监听。

### Q: 应该填写哪个 IP？

可通过以下命令查询服务器看到的公网 IPv4：

```bash
curl -4 https://icanhazip.com
```

最终 URL 通常为 `http://<公网 IPv4>:3340`。如果服务器位于 NAT 后，还需要在
上游路由器配置端口转发。

### Q: 为什么日志里没有监听 URL？

当前 `iroh-relay --dev` 不保证打印可供外部访问的 URL。systemd 日志中的
`Started iroh-relay.service` 只表示进程已启动。请使用 `ss` 确认监听端口，
并自行组合服务器公网 IP 与端口 3340。

### Q: 还需要开放端口吗？

需要。请在云服务商安全组和服务器防火墙中允许入站 TCP 3340。若端口未开放，
服务即使在本机正常监听，公网玩家也无法访问。

### Q: 加入方也需要配置自建 Relay 吗？

不需要手动配置。建房方启用自建 Relay 后，生成的 `sculk://` 票据会包含 Relay
URL；加入方使用完整票据即可。建房方应在切换 Relay 后重新建房并分享新票据。

### Q: 自建 Relay 不可用时会回退到 n0 Relay 吗？

不会。sculk 仍可能通过 P2P 直连建立连接；如果直连和票据指定的自建 Relay
都不可用，连接会重试并最终失败。已连接后的自动重连也不会切换到 n0 Relay。

### Q: 如何停止服务？

临时停止：

```bash
sudo systemctl stop iroh-relay
```

停止并取消开机自启：

```bash
sudo systemctl disable --now iroh-relay
```

### Q: `--dev` 适合长期公网使用吗？

不适合。`--dev` 使用明文 HTTP，主要用于测试。长期部署应使用域名和 TLS，
并根据实际流量配置访问控制、监控和带宽限制。
