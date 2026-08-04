# iroh-relay

<kbd>[English](README-en.md)</kbd>

本仓库提供适用于 Linux amd64 和 arm64 的 `iroh-relay` 预编译文件，用于部署
[sculk](https://github.com/KercyDing/sculk) 自建 Relay 服务器。

## 安装

CNB 镜像源，推荐：

```bash
bash -c "$(curl -fsSL https://cnb.cool/SeaLantern-studio/iroh-relay/-/git/raw/main/script.sh)"
```

GitHub 源：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/KercyDing/iroh-relay/main/script.sh)"
```

脚本会自动识别架构、下载校验、安装、配置并启动 systemd 服务，最后输出 Relay URL。

## 使用

安装脚本会创建并启动 systemd 服务，最后输出 Relay URL。将该 URL 填入 sculk 的
自建中继设置即可。请在云服务商安全组、服务器防火墙和 NAT 路由器中开放 TCP 3340。

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

### Q: 加入方也需要配置自建 Relay 吗？

不需要手动配置。建房方启用自建 Relay 后，生成的 `sculk://` 票据会包含 Relay
URL；加入方使用完整票据即可。建房方应在切换 Relay 后重新建房并分享新票据。

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

## 许可证

[Apache License 2.0](LICENSE)
