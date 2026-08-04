#!/usr/bin/env bash

set -euo pipefail

GITHUB_RELEASE_BASE="https://github.com/KercyDing/iroh-relay/releases/latest/download"
CNB_RELEASES_URL="https://cnb.cool/SeaLantern-studio/iroh-relay/-/releases"
CNB_RELEASE_BASE="https://cnb.cool/SeaLantern-studio/iroh-relay/-/releases/download"
DESTINATION="${IROH_RELAY_DESTINATION:-/usr/local/bin/iroh-relay}"
SERVICE_FILE="/etc/systemd/system/iroh-relay.service"
RELAY_PORT="3340"

case "$(uname -m)" in
  x86_64) asset="iroh-relay-linux-amd64" ;;
  aarch64 | arm64) asset="iroh-relay-linux-arm64" ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "iroh-relay is only distributed for Linux." >&2
  exit 1
fi

for command in curl grep install sha256sum systemctl; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "Required command is unavailable: ${command}" >&2
    exit 1
  fi
done

if [[ "${EUID}" -eq 0 ]]; then
  sudo_command=()
else
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to install iroh-relay and configure systemd." >&2
    exit 1
  fi
  sudo_command=(sudo)
  sudo -v
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

download_and_verify() {
  local base_url="$1"
  local label="$2"

  echo "Downloading ${asset} from ${label}..."
  curl --fail --location --silent --show-error --output "${work_dir}/${asset}" "${base_url}/${asset}"
  curl --fail --location --silent --show-error --output "${work_dir}/${asset}.sha256" "${base_url}/${asset}.sha256"
  (
    cd "${work_dir}"
    sha256sum --check --status "${asset}.sha256"
  )
}

latest_cnb_tag() {
  curl --fail --location --silent --show-error "${CNB_RELEASES_URL}" |
    grep -oE '/SeaLantern-studio/iroh-relay/-/releases/tag/v[0-9][^"< ]*' |
    sed 's#.*/##' |
    sed -n '1p'
}

cnb_tag="$(latest_cnb_tag || true)"
if [[ "${cnb_tag}" =~ ^v[0-9] ]]; then
  if ! download_and_verify "${CNB_RELEASE_BASE}/${cnb_tag}" "CNB (${cnb_tag})"; then
    echo "CNB mirror failed; falling back to GitHub." >&2
    download_and_verify "${GITHUB_RELEASE_BASE}" "GitHub"
  fi
else
  echo "No CNB release found; falling back to GitHub." >&2
  download_and_verify "${GITHUB_RELEASE_BASE}" "GitHub"
fi

"${sudo_command[@]}" install -m 0755 "${work_dir}/${asset}" "${DESTINATION}"

cat <<EOF | "${sudo_command[@]}" tee "${SERVICE_FILE}" >/dev/null
[Unit]
Description=Iroh Relay Server (dev mode, plain HTTP)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=${DESTINATION} --dev
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

"${sudo_command[@]}" systemctl daemon-reload
"${sudo_command[@]}" systemctl enable iroh-relay >/dev/null
"${sudo_command[@]}" systemctl restart iroh-relay

if ! "${sudo_command[@]}" systemctl is-active --quiet iroh-relay; then
  echo "iroh-relay failed to start. Recent logs:" >&2
  "${sudo_command[@]}" journalctl --unit iroh-relay --no-pager --lines 30 >&2
  exit 1
fi

public_ip="$(
  curl --fail --location --silent --show-error --connect-timeout 5 --max-time 10 -4 https://api.ipify.org 2>/dev/null ||
    curl --fail --location --silent --show-error --connect-timeout 5 --max-time 10 -4 https://icanhazip.com 2>/dev/null ||
    true
)"
public_ip="${public_ip//$'\n'/}"

echo
echo "iroh-relay is running."
echo "Binary: ${DESTINATION}"
echo "Service: sudo systemctl status iroh-relay"
if [[ "${public_ip}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo
  echo "Relay URL: http://${public_ip}:${RELAY_PORT}"
  echo "Allow inbound TCP ${RELAY_PORT} in your cloud security group, firewall, and NAT router if applicable."
else
  echo
  echo "Could not determine the public IPv4 address."
  echo "Relay URL format: http://<your-public-ip>:${RELAY_PORT}"
  echo "Allow inbound TCP ${RELAY_PORT} in your cloud security group, firewall, and NAT router if applicable."
fi
