#!/usr/bin/env bash
set -euo pipefail

OS="$(uname)"

echo "[install] Detected OS: $OS"

install_yq_linux() {
  echo "[install] Installing yq (Linux)..."
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64) YQ_BIN="yq_linux_amd64" ;;
    aarch64|arm64) YQ_BIN="yq_linux_arm64" ;;
    armv7l) YQ_BIN="yq_linux_arm" ;;
    *) echo "Unsupported arch: $ARCH"; exit 1 ;;
  esac
  sudo wget -q "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BIN}" -O /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
}

install_yq_mac() {
  echo "[install] Installing yq (macOS via Homebrew)..."
  brew install yq || true
}

if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "[install] Homebrew missing, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
