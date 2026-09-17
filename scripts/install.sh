#!/usr/bin/env bash
set -euo pipefail

OS="$(uname)"

# Pin yq release (Dependabot cannot track this binary download).
YQ_VERSION="${YQ_VERSION:-v4.53.6}"

echo "[install] Detected OS: $OS"

yq_sha256_for() {
  case "$1" in
    yq_linux_amd64) echo "c5f056448f973ae7d39b5401949648a78f2dc1947d6a8eb65be60d5c504b9385" ;;
    yq_linux_arm64) echo "88a1016bc1d657375a35864e4f44b6f333df8ff97b559f51bba0adcb2169df09" ;;
    yq_linux_arm)   echo "42d231dc5acaa7b30bc78630a423563d1363217ec261bb33da3b9865b474c485" ;;
    *) return 1 ;;
  esac
}

install_yq_linux() {
  echo "[install] Installing yq ${YQ_VERSION} (Linux, checksum verified)..."
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64) YQ_BIN="yq_linux_amd64" ;;
    aarch64|arm64) YQ_BIN="yq_linux_arm64" ;;
    armv7l) YQ_BIN="yq_linux_arm" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac
  YQ_SHA256="$(yq_sha256_for "$YQ_BIN")" || { echo "No checksum for $YQ_BIN"; exit 1; }
  TMP="$(mktemp)"
  sudo wget -q "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BIN}" -O "$TMP"
  echo "${YQ_SHA256}  ${TMP}" | sha256sum -c -
  sudo install -m 0755 "$TMP" /usr/local/bin/yq
  rm -f "$TMP"
}

install_yq_mac() {
  echo "[install] Installing yq (macOS via Homebrew)..."
  brew install yq || true
}

if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "[install] Homebrew missing. Install from https://brew.sh (avoid piping unpinned installers)."
    exit 1
  fi
  brew install tmux coreutils || true
  command -v yq >/dev/null 2>&1 || install_yq_mac

elif [[ "$OS" == "Linux" ]]; then
  echo "[install] Installing dependencies on Linux..."
  sudo apt update
  sudo apt install -y tmux ssh wget || true
  command -v yq >/dev/null 2>&1 || install_yq_linux
else
  echo "[install] Unsupported OS: $OS"
  exit 1
fi

echo "[install] Done. Run: ./scripts/manager.sh"
