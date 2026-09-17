#!/usr/bin/env bash
# pane.sh – persistent SSH pane runner with visible failure output
set -euo pipefail

HOST="$1"
USER="$2"
KEY="$3"
SCRIPT="$4"

export TERM=xterm-256color

SSH_OPTS=(
  -tt
  -i "$KEY"
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=accept-new
  -o ConnectTimeout=5
  -o ServerAliveInterval=10
  -o ServerAliveCountMax=3
)

while true; do
  echo "[pane/$HOST] Connecting as $USER using key $KEY ..."

  ssh "${SSH_OPTS[@]}" \
      "$USER@$HOST" "bash -c '$SCRIPT'" || {

        echo
        echo "============================================="
        echo " SSH FAILURE on $HOST"
        echo "---------------------------------------------"
        echo "Time: $(date)"
        echo "User: $USER"
        echo "Key : $KEY"
        echo "---------------------------------------------"
        echo "Error occurred. Retrying in 3 seconds..."
        echo "============================================="
        echo
      }

  sleep 3
done
