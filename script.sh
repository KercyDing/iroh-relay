#!/usr/bin/env bash

set -euo pipefail

GITHUB_RELEASE_BASE="https://github.com/KercyDing/iroh-relay/releases/latest/download"
CNB_RELEASES_URL="https://cnb.cool/SeaLantern-studio/iroh-relay/-/releases"
CNB_RELEASE_BASE="https://cnb.cool/SeaLantern-studio/iroh-relay/-/releases/download"
DESTINATION="${IROH_RELAY_DESTINATION:-/usr/local/bin/iroh-relay}"

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

if [[ -w "$(dirname "${DESTINATION}")" ]]; then
  install -m 0755 "${work_dir}/${asset}" "${DESTINATION}"
else
  sudo install -m 0755 "${work_dir}/${asset}" "${DESTINATION}"
fi

echo "Installed iroh-relay to ${DESTINATION}"
