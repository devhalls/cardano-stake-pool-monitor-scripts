#!/usr/bin/env bash
# Usage: fleet.sh (
#   status |
#   check |
#   dry-run |
#   update |
#   help
# ) [--version VERSION] [--hosts PATTERN] [--yes] [--no-pull]
#
# Info:
#
#   SSH fleet tool for spo-operational-scripts node updates.
#   Inventory: ../hosts.yaml (same as manager.sh).
#   Ordering: relays in parallel, then producers sequentially.
#   Abort producers if any selected relay fails.
#
#   - status)  Per-host env NODE_VERSION, running binary version, optional tip slot
#   - check)   SSH connectivity (key + BatchMode login)
#   - dry-run) Print ordered update plan without mutating remotes
#   - update)  git pull → set NODE_VERSION → node.sh update --yes → verify
#   - help)    Show this usage

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${PROJECT_DIR}/../hosts.yaml"

CMD=""
TARGET_VERSION=""
HOST_FILTER=""
ASSUME_YES=0
NO_PULL=0

usage() {
  sed -n '2,22p' "$0" | sed -e 's/^# //' -e 's/^#//'
  exit "${1:-1}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    status | check | dry-run | update | help | -h | --help)
      CMD="$1"
      shift
      ;;
    --version)
      TARGET_VERSION="${2:-}"
      [[ -n "$TARGET_VERSION" ]] || { echo "error: --version requires a value"; usage 1; }
      shift 2
      ;;
    --hosts)
      HOST_FILTER="${2:-}"
      [[ -n "$HOST_FILTER" ]] || { echo "error: --hosts requires a pattern"; usage 1; }
      shift 2
      ;;
    --yes | -y)
      ASSUME_YES=1
      shift
      ;;
    --no-pull)
      NO_PULL=1
      shift
      ;;
    *)
      echo "error: unknown argument: $1"
      usage 1
      ;;
  esac
done

case "${CMD:-}" in
  help | -h | --help) usage 0 ;;
  status | check | dry-run | update) ;;
  "")
    echo "error: command required (status|check|dry-run|update|help)"
    usage 1
    ;;
esac

command -v yq >/dev/null 2>&1 || { echo "yq not found. Run ./scripts/install.sh"; exit 1; }

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing $CONFIG_FILE. Copy hosts.example.yaml and edit it."
  exit 1
fi

HOST_COUNT="$(yq -r '.hosts | length' "$CONFIG_FILE")"
if [[ "$HOST_COUNT" -eq 0 ]]; then
  echo "No hosts defined in $CONFIG_FILE"
  exit 1
fi

# Expand leading ~/ in paths
expand_path() {
  local p="$1"
  if [[ "$p" == ~* ]]; then
    p="${p/#\~/$HOME}"
  fi
  printf '%s' "$p"
}

# Derive workdir from first pane script: "bash Cardano/scripts/node.sh view" → Cardano
derive_workdir() {
  local idx="$1"
  local script workdir
  script="$(yq -r ".hosts[$idx].panes[0].script // \"\"" "$CONFIG_FILE")"
  [[ -n "$script" && "$script" != "null" ]] || return 1
  # Prefer path containing /scripts/node.sh
  if [[ "$script" =~ ([^[:space:]]+)/scripts/node\.sh ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  # Fallback: first path-like token
  for tok in $script; do
    if [[ "$tok" == */* ]]; then
      workdir="${tok%%/scripts/*}"
      workdir="${workdir%/}"
      [[ -n "$workdir" ]] && { printf '%s' "$workdir"; return 0; }
    fi
  done
  return 1
}

host_field() {
  local idx="$1" field="$2"
  yq -r ".hosts[$idx].${field} // \"\"" "$CONFIG_FILE"
}

host_title() {
  local idx="$1" t
  t="$(host_field "$idx" title)"
  if [[ -z "$t" || "$t" == "null" ]]; then
    t="host-$((idx + 1))"
  fi
  printf '%s' "$t"
}

host_role() {
  local idx="$1" r
  r="$(host_field "$idx" role)"
  r="$(echo "$r" | tr '[:upper:]' '[:lower:]')"
  case "$r" in
    relay | producer) printf '%s' "$r" ;;
    *) printf '%s' "" ;;
  esac
}

host_workdir() {
  local idx="$1" w
  w="$(host_field "$idx" workdir)"
  if [[ -n "$w" && "$w" != "null" ]]; then
    printf '%s' "$w"
    return 0
  fi
  derive_workdir "$idx" || true
}

host_matches_filter() {
  local idx="$1" title
  [[ -z "$HOST_FILTER" ]] && return 0
  title="$(host_title "$idx")"
  [[ "$title" =~ $HOST_FILTER ]]
}

# Collect filtered host indices into arrays RELAY_IDXS / PRODUCER_IDXS / OTHER_IDXS
RELAY_IDXS=()
PRODUCER_IDXS=()
OTHER_IDXS=()

collect_hosts() {
  local i role
  RELAY_IDXS=()
  PRODUCER_IDXS=()
  OTHER_IDXS=()
  for ((i = 0; i < HOST_COUNT; i++)); do
    host_matches_filter "$i" || continue
    role="$(host_role "$i")"
    case "$role" in
      relay) RELAY_IDXS+=("$i") ;;
      producer) PRODUCER_IDXS+=("$i") ;;
      *) OTHER_IDXS+=("$i") ;;
    esac
  done
}

ssh_run() {
  local host="$1" user="$2" key="$3" remote="$4" title="${5:-$host}"
  local key_exp outfile rc line
  key_exp="$(expand_path "$key")"
  outfile="$(mktemp "${TMPDIR:-/tmp}/fleet-ssh.XXXXXX")"
  set +e
  printf '%s\n' "$remote" | ssh -i "$key_exp" \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o IdentitiesOnly=yes \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    "$user@$host" bash -s >"$outfile" 2>&1
  rc=$?
  set -e
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '[%s] %s\n' "$title" "$line"
  done <"$outfile"
  rm -f "$outfile"
  return "$rc"
}

fleet_confirm() {
  local msg="$1"
  if [[ "$ASSUME_YES" == "1" ]]; then
    echo "[fleet] Skipping confirm (--yes)"
    return 0
  fi
  read -r -p "$msg ([y]es or [N]o): " reply
  case "$(echo "$reply" | tr '[:upper:]' '[:lower:]')" in
    y | yes) return 0 ;;
    *)
      echo "Cancelled."
      return 1
      ;;
  esac
}

cmd_check() {
  local i host user key key_exp title ok=0 fail=0
  echo "[fleet] SSH checklist ($CONFIG_FILE)"
  echo
  for ((i = 0; i < HOST_COUNT; i++)); do
    host_matches_filter "$i" || continue
    title="$(host_title "$i")"
    host="$(host_field "$i" ip)"
    user="$(host_field "$i" user)"
    key="$(host_field "$i" key)"
    key_exp="$(expand_path "$key")"
    echo "=== $title ($user@$host) ==="
    if [[ ! -f "$key_exp" ]]; then
      echo "  [X] Key missing: $key_exp"
      fail=$((fail + 1))
      echo
      continue
    fi
    echo "  [✓] Key exists: $key_exp"
    if ssh -i "$key_exp" -o BatchMode=yes -o ConnectTimeout=5 -o IdentitiesOnly=yes \
      "$user@$host" "echo ok" 2>/dev/null | grep -q "ok"; then
      echo "  [✓] SSH BatchMode login works"
      ok=$((ok + 1))
    else
      echo "  [X] SSH BatchMode login FAILED"
      fail=$((fail + 1))
    fi
    echo
  done
  echo "[fleet] check summary: ok=$ok fail=$fail"
  [[ "$fail" -eq 0 ]]
}

cmd_status() {
  local i host user key title role workdir remote
  collect_hosts
  echo "[fleet] status"
  echo
  local idxs=()
  [[ ${#RELAY_IDXS[@]} -gt 0 ]] && idxs+=("${RELAY_IDXS[@]}")
  [[ ${#PRODUCER_IDXS[@]} -gt 0 ]] && idxs+=("${PRODUCER_IDXS[@]}")
  [[ ${#OTHER_IDXS[@]} -gt 0 ]] && idxs+=("${OTHER_IDXS[@]}")
  for i in "${idxs[@]}"; do
    title="$(host_title "$i")"
    host="$(host_field "$i" ip)"
    user="$(host_field "$i" user)"
    key="$(host_field "$i" key)"
    role="$(host_role "$i")"
    workdir="$(host_workdir "$i")"
    [[ -n "$role" ]] || echo "[$title] warning: no role set (skipped by update)"
    [[ -n "$workdir" ]] || echo "[$title] warning: no workdir (set workdir or a pane with scripts/node.sh)"
    if [[ -z "$workdir" ]]; then
      continue
    fi
    remote=$(
      cat <<REMOTE
set -euo pipefail
cd "$workdir" || { echo "workdir missing: $workdir"; exit 1; }
if [[ -f env ]]; then
  grep -E '^NODE_VERSION=' env | head -1 || echo "NODE_VERSION=(unset)"
else
  echo "NODE_VERSION=(no env file)"
fi
if [[ -x scripts/node.sh ]]; then
  echo -n "running="
  scripts/node.sh update current 2>/dev/null || echo "(unavailable)"
  if scripts/query.sh tip slot >/tmp/fleet_tip 2>/dev/null; then
    echo -n "tip_slot="
    cat /tmp/fleet_tip
  else
    echo "tip_slot=(unavailable)"
  fi
else
  echo "running=(no scripts/node.sh)"
fi
REMOTE
    )
    ssh_run "$host" "$user" "$key" "$remote" "$title" || echo "[$title] status query failed"
    echo
  done
}

print_plan_host() {
  local idx="$1" phase="$2"
  local title role workdir host
  title="$(host_title "$idx")"
  role="$(host_role "$idx")"
  workdir="$(host_workdir "$idx")"
  host="$(host_field "$idx" ip)"
  echo "  [$phase] $title  role=${role:-?}  host=$host  workdir=${workdir:-?}  version=${TARGET_VERSION:-'(keep env)'}  pull=$([[ "$NO_PULL" == 1 ]] && echo no || echo yes)"
}

cmd_dry_run() {
  local i
  collect_hosts
  if [[ -z "$TARGET_VERSION" ]]; then
    echo "[fleet] dry-run: --version not set (will only pull + update to whatever NODE_VERSION is in remote env after pull)"
  fi
  echo "[fleet] planned order:"
  if [[ ${#RELAY_IDXS[@]} -gt 0 ]]; then
    echo " Relays (parallel):"
    for i in "${RELAY_IDXS[@]}"; do print_plan_host "$i" "relay"; done
  else
    echo " Relays: (none)"
  fi
  if [[ ${#PRODUCER_IDXS[@]} -gt 0 ]]; then
    echo " Producers (sequential, after relays OK):"
    for i in "${PRODUCER_IDXS[@]}"; do print_plan_host "$i" "producer"; done
  else
    echo " Producers: (none)"
  fi
  if [[ ${#OTHER_IDXS[@]} -gt 0 ]]; then
    echo " Skipped (no role):"
    for i in "${OTHER_IDXS[@]}"; do
      echo "  - $(host_title "$i")"
    done
  fi
}

update_remote_payload() {
  local workdir="$1" version="$2" no_pull="$3"
  cat <<REMOTE
set -euo pipefail
cd "$workdir" || { echo "workdir missing: $workdir"; exit 1; }
[[ -f env ]] || { echo "missing env in $workdir"; exit 1; }
[[ -x scripts/node.sh ]] || { echo "missing scripts/node.sh in $workdir"; exit 1; }
if [[ "$no_pull" != "1" ]]; then
  echo "git pull --ff-only"
  git pull --ff-only
fi
if [[ -n "$version" ]]; then
  echo "set NODE_VERSION=$version"
  if grep -qE '^NODE_VERSION=' env; then
    sed -i.bak "s/^NODE_VERSION=.*/NODE_VERSION=$version/" env
  else
    echo "NODE_VERSION=$version" >> env
  fi
fi
echo "node.sh update --yes"
./scripts/node.sh update --yes
echo -n "verify running="
./scripts/node.sh update current
REMOTE
}

update_one_host() {
  local idx="$1"
  local title host user key workdir role remote
  title="$(host_title "$idx")"
  host="$(host_field "$idx" ip)"
  user="$(host_field "$idx" user)"
  key="$(host_field "$idx" key)"
  role="$(host_role "$idx")"
  workdir="$(host_workdir "$idx")"

  if [[ -z "$role" ]]; then
    echo "[$title] skip: no role"
    return 2
  fi
  if [[ -z "$workdir" ]]; then
    echo "[$title] fail: no workdir"
    return 1
  fi

  remote="$(update_remote_payload "$workdir" "$TARGET_VERSION" "$NO_PULL")"
  echo "[$title] updating ($role) ..."
  ssh_run "$host" "$user" "$key" "$remote" "$title"
}

cmd_update() {
  local i tmpdir pids=() status_files=() relay_fail=0 producer_fail=0 rc title

  collect_hosts

  if [[ ${#RELAY_IDXS[@]} -eq 0 && ${#PRODUCER_IDXS[@]} -eq 0 ]]; then
    echo "error: no hosts with role relay|producer matched (set role in hosts.yaml or adjust --hosts)"
    exit 1
  fi

  cmd_dry_run
  echo
  fleet_confirm "Proceed with fleet update on the hosts above?" || exit 1

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/fleet-update.XXXXXX")"
  trap 'rm -rf "$tmpdir"' EXIT

  # Relays in parallel
  if [[ ${#RELAY_IDXS[@]} -gt 0 ]]; then
    echo
    echo "[fleet] updating relays in parallel ..."
    pids=()
    status_files=()
    for i in "${RELAY_IDXS[@]}"; do
      title="$(host_title "$i")"
      sf="$tmpdir/relay-$i.status"
      status_files+=("$sf")
      (
        if update_one_host "$i"; then
          echo 0 >"$sf"
        else
          echo $? >"$sf"
        fi
      ) &
      pids+=("$!")
    done
    for p in "${pids[@]}"; do
      wait "$p" || true
    done
    for sf in "${status_files[@]}"; do
      rc="$(cat "$sf" 2>/dev/null || echo 1)"
      if [[ "$rc" != "0" ]]; then
        relay_fail=$((relay_fail + 1))
      fi
    done
    if [[ "$relay_fail" -gt 0 ]]; then
      echo "[fleet] aborting producers: $relay_fail relay(s) failed"
      echo "[fleet] summary: relays_failed=$relay_fail producers_skipped=${#PRODUCER_IDXS[@]}"
      exit 1
    fi
    echo "[fleet] all relays OK"
  fi

  # Producers sequential
  if [[ ${#PRODUCER_IDXS[@]} -gt 0 ]]; then
    echo
    echo "[fleet] updating producers sequentially ..."
    for i in "${PRODUCER_IDXS[@]}"; do
      if ! update_one_host "$i"; then
        producer_fail=$((producer_fail + 1))
        echo "[fleet] producer failed: $(host_title "$i")"
      fi
    done
  fi

  echo
  echo "[fleet] summary: relays_ok=$((${#RELAY_IDXS[@]} - relay_fail)) relays_fail=$relay_fail producers_fail=$producer_fail"
  [[ "$producer_fail" -eq 0 ]]
}

case "$CMD" in
  check) cmd_check ;;
  status) cmd_status ;;
  dry-run) collect_hosts; cmd_dry_run ;;
  update) cmd_update ;;
esac
