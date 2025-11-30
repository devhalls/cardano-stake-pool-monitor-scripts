#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DEFAULT="lan-monitor"
SESSION_NAME="${1:-$SESSION_DEFAULT}"

# This is intended to be run from inside tmux via run-shell
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
"$PROJECT_DIR/manager.sh" "$SESSION_NAME" &
