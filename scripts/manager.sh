#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${PROJECT_DIR}/../hosts.yaml"
SESSION_DEFAULT="lan-monitor"

MODE="run"
SESSION_NAME="$SESSION_DEFAULT"
if [[ "${1:-}" == "--check" ]]; then
  MODE="check"
elif [[ "${1:-}" != "" ]]; then
  SESSION_NAME="$1"
fi

command -v tmux >/dev/null 2>&1 || { echo "tmux not found. Run ./scripts/install.sh"; exit 1; }
command -v yq   >/dev/null 2>&1 || { echo "yq not found. Run ./scripts/install.sh"; exit 1; }

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing $CONFIG_FILE. Create it first."
  exit 1
fi

HOST_COUNT="$(yq -r '.hosts | length' "$CONFIG_FILE")"
if [[ "$HOST_COUNT" -eq 0 ]]; then
  echo "No hosts defined in $CONFIG_FILE"
  exit 1
fi

# ---------------------------------------------------------
# SSH CHECKLIST MODE
# ---------------------------------------------------------
check_hosts() {
  echo "[SSH CHECKLIST] Validating hosts from $CONFIG_FILE"
  echo

  for ((i=0; i<HOST_COUNT; i++)); do
    host="$(yq -r ".hosts[$i].ip"   "$CONFIG_FILE")"
    user="$(yq -r ".hosts[$i].user" "$CONFIG_FILE")"
    key="$(yq -r ".hosts[$i].key"  "$CONFIG_FILE")"

    echo "Host #$((i+1)): $user@$host (key: $key)"

    if [[ ! -f "$key" ]]; then
      echo "  [X] Key file missing: $key"
      echo
      continue
    else
      echo "  [✓] Key file exists"
    fi

    perm="$(stat -c '%a' "$key" 2>/dev/null || stat -f '%Lp' "$key" 2>/dev/null || echo '???')"
    echo "  [i] Key permissions: $perm (recommend 600)"

    if ping -c1 -W1 "$host" &>/dev/null; then
      echo "  [✓] Host reachable (ping)"
    else
      echo "  [X] Host not reachable by ping"
    fi

    if ssh -i "$key" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$user@$host" "echo ok" 2>/dev/null | grep -q "ok"; then
      echo "  [✓] SSH key-based login works (no password prompt)"
    else
      echo "  [X] SSH key-based login FAILED"
      echo "      Check authorized_keys and ~/.ssh permissions."
    fi

    echo
  done

  cat <<EOF
[SSH CHECKLIST SUMMARY]

Ensure:
  - Dedicated monitor key (least privilege; not your producer admin key)
  - ssh-keygen -t ed25519 -f ~/.ssh/cardano_monitor
  - ssh-copy-id -i ~/.ssh/cardano_monitor.pub user@host
  - Host keys recorded in ~/.ssh/known_hosts (StrictHostKeyChecking=accept-new on first connect)
  - ~/.ssh perms: 700
  - authorized_keys perms: 600
  - hosts.yaml perms: 600 (inventory-sensitive; never commit)

EOF
}

if [[ "$MODE" == "check" ]]; then
  check_hosts
  exit 0
fi

# ---------------------------------------------------------
# WINDOW + PANE CREATION
# ---------------------------------------------------------
create_host_windows() {
  local i host user key pane_count window_name script color title

  for ((i=0; i<HOST_COUNT; i++)); do
    host="$(yq -r ".hosts[$i].ip"   "$CONFIG_FILE")"
    user="$(yq -r ".hosts[$i].user" "$CONFIG_FILE")"
    key="$(yq -r ".hosts[$i].key"  "$CONFIG_FILE")"
    pane_count="$(yq -r ".hosts[$i].panes | length" "$CONFIG_FILE")"

    [[ "$pane_count" -eq 0 ]] && continue
    window_name="host-$((i+1))"

    script="$(yq -r ".hosts[$i].panes[0].script" "$CONFIG_FILE")"
    color="$(yq -r ".hosts[$i].panes[0].color"  "$CONFIG_FILE")"
    title="$(yq -r ".hosts[$i].panes[0].title // \"\"" "$CONFIG_FILE")"

    tmux new-window -t "$SESSION_NAME" -n "$window_name" \
      "bash \"$PROJECT_DIR/pane.sh\" \"$host\" \"$user\" \"$key\" \"$script\""

    [[ -n "$title" && "$title" != "null" ]] && tmux select-pane -t "$SESSION_NAME:$window_name".0 -T "$title"
    [[ "$color" != "null" ]] && tmux select-pane -t "$SESSION_NAME:$window_name".0 -P "fg=$color"

    tmux split-window -h -t "$SESSION_NAME:$window_name" "sleep 0.1"
    local right_col="1"

    for ((p=1; p<pane_count; p++)); do
      script="$(yq -r ".hosts[$i].panes[$p].script" "$CONFIG_FILE")"
      color="$(yq -r ".hosts[$i].panes[$p].color"  "$CONFIG_FILE")"
      title="$(yq -r ".hosts[$i].panes[$p].title // \"\"" "$CONFIG_FILE")"
      height="$(yq -r ".hosts[$i].panes[$p].height // \"\"" "$CONFIG_FILE")"

      if [[ $p -eq 1 ]]; then
        tmux respawn-pane -t "$SESSION_NAME:$window_name"."$right_col" -k \
          "bash \"$PROJECT_DIR/pane.sh\" \"$host\" \"$user\" \"$key\" \"$script\""
        [[ -n "$height" && "$height" != "null" ]] && tmux resize-pane -t "$SESSION_NAME:$window_name"."$right_col" -y "$height"
      else
        if [[ -n "$height" && "$height" != "null" ]]; then
          tmux split-window -v -l "$height" -t "$SESSION_NAME:$window_name"."$right_col" \
            "bash \"$PROJECT_DIR/pane.sh\" \"$host\" \"$user\" \"$key\" \"$script\""
        else
          tmux split-window -v -t "$SESSION_NAME:$window_name"."$right_col" \
            "bash \"$PROJECT_DIR/pane.sh\" \"$host\" \"$user\" \"$key\" \"$script\""
        fi
      fi

      [[ -n "$title" && "$title" != "null" ]] && tmux select-pane -T "$title"
      [[ "$color" != "null" ]] && tmux select-pane -P "fg=$color"
    done

    col_width="$(yq -r ".hosts[$i].second_column // \"100\"" "$CONFIG_FILE")"
    tmux resize-pane -t "$SESSION_NAME:$window_name".1 -x "$col_width"
  done
}

# If session already exists, just attach
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session '$SESSION_NAME' already exists, attaching..."
  exec tmux attach -t "$SESSION_NAME"
fi

setup_keybindings() {
  # Visual theme
  tmux set-option -g aggressive-resize on
  tmux set-option -g status-interval 5
  tmux set-option -g status-style "bg=black,fg=white"
  tmux set-option -g status-left-length 120
  tmux set-option -g status-left "[1..9] hosts  [d] dashboard  [r] restart  [c] color  [x] quit  | "
  tmux set-option -g status-right 'Node Monitor | v0.1 | #(date +"%Y-%m-%d %H:%M")'
  tmux set-option -g window-active-style 'fg=default,bg=default'
  tmux set-option -g window-style        'fg=default,bg=default'
  tmux set-option -g pane-border-status top
  tmux set-option -g pane-border-format " #{pane_title} "
  tmux set-option -g pane-border-style fg=white
  tmux set-option -g pane-active-border-style fg=green

  # Pane actions
  tmux bind-key -n r run-shell "tmux respawn-pane -k"
  tmux bind-key -n c run-shell "$PROJECT_DIR/pane_cycle.sh"

  # Window navigation (relative to current session)
  tmux bind-key -n d select-window -t :Dashboard

  # Dynamic numeric host navigation: 1, 2, 3, ...
  for ((i=0; i<HOST_COUNT && i<9; i++)); do
    num="$((i+1))"
    win_name="host-$num"
    tmux bind-key -n "$num" select-window -t :"$win_name"
  done

  # Simple pane navigation with arrows (left/right)
  tmux bind-key -n Right select-pane -t :.+
  tmux bind-key -n Left  select-pane -t :.-

  # Kill whole session with 'x'
  tmux bind-key -n x kill-session
}

create_dashboard_window() {
  # Create the dashboard window *with* the final name directly
  tmux new-window -t "$SESSION_NAME" -n "Dashboard" \
    "bash \"$PROJECT_DIR/dashboard.sh\" \"$CONFIG_FILE\""

  # Set pane title for the first (and only) pane in the Dashboard window
  tmux select-pane -t "$SESSION_NAME:Dashboard.0" -T "Dashboard"
}

echo "[lan-monitor] Creating tmux session '$SESSION_NAME'..."

# Start base session with dummy window so we can configure it
tmux new-session -d -s "$SESSION_NAME" -n "init" "sleep 1"
setup_keybindings
create_host_windows
create_dashboard_window
tmux kill-window -t "$SESSION_NAME:init"

echo "[lan-monitor] Session ready. Attach with:"
echo "  tmux attach -t $SESSION_NAME"
tmux attach -t "$SESSION_NAME"
