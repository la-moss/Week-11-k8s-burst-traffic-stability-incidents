#!/usr/bin/env bash
set -euo pipefail

NS="${VERIFY_NAMESPACE:-incident-lab}"
PROFILE="${VERIFY_PROFILE:-profile1}"
REQUESTS="${VERIFY_REQUESTS:-24}"
PORT="${VERIFY_PORT:-18080}"

echo "[runtime] waiting for deployments..."
kubectl -n "$NS" rollout status deploy/worker --timeout=180s >/dev/null
kubectl -n "$NS" rollout status deploy/api --timeout=180s >/dev/null

kubectl -n "$NS" port-forward svc/api "$PORT":8080 >/tmp/week1-pf.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID >/dev/null 2>&1 || true' EXIT
sleep 2

successes=0
client_errors=0
server_errors=0
latency_sum_ms=0
latencies_ms=()

for _ in $(seq 1 "$REQUESTS"); do
  out=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" "http://127.0.0.1:$PORT/" || echo "000 0")
  code=$(echo "$out" | awk '{print $1}')
  ttotal=$(echo "$out" | awk '{print $2}')
  latency_ms=$(awk -v t="$ttotal" 'BEGIN { printf("%.0f", t * 1000) }')
  latencies_ms+=("$latency_ms")
  latency_sum_ms=$((latency_sum_ms + latency_ms))

  if [[ "$code" =~ ^2 ]]; then
    successes=$((successes + 1))
  elif [[ "$code" =~ ^4 ]]; then
    client_errors=$((client_errors + 1))
  elif [[ "$code" =~ ^5 ]]; then
    server_errors=$((server_errors + 1))
  fi
done

IFS=$'\n' sorted=($(printf "%s\n" "${latencies_ms[@]}" | sort -n))
unset IFS
idx=$(( (95 * REQUESTS + 99) / 100 - 1 ))
if [[ "$idx" -lt 0 ]]; then idx=0; fi
if [[ "$idx" -ge "$REQUESTS" ]]; then idx=$((REQUESTS - 1)); fi
p95_latency_ms="${sorted[$idx]}"
avg_latency_ms=$((latency_sum_ms / REQUESTS))

success_rate_bp=$((successes * 10000 / REQUESTS))
success_rate_pct=$(awk -v bp="$success_rate_bp" 'BEGIN { printf("%.2f", bp/100) }')
client_error_rate_bp=$((client_errors * 10000 / REQUESTS))
client_error_rate_pct=$(awk -v bp="$client_error_rate_bp" 'BEGIN { printf("%.2f", bp/100) }')
server_error_rate_bp=$((server_errors * 10000 / REQUESTS))
server_error_rate_pct=$(awk -v bp="$server_error_rate_bp" 'BEGIN { printf("%.2f", bp/100) }')

restart_count=$(kubectl -n "$NS" get pods -l app=api -o jsonpath='{range .items[*]}{range .status.containerStatuses[*]}{.restartCount}{"\n"}{end}{end}' | awk '{s+=$1} END{print s+0}')
oomkill_events=$(kubectl -n "$NS" get pods -l app=api -o jsonpath='{range .items[*]}{range .status.containerStatuses[*]}{.lastState.terminated.reason}{"\n"}{end}{end}' | awk '/OOMKilled/{c++} END{print c+0}')
ready_api=$(kubectl -n "$NS" get deploy api -o jsonpath='{.status.readyReplicas}')
ready_api=${ready_api:-0}

echo "[runtime] profile=$PROFILE"
echo "[runtime] availability.success_rate_pct=$success_rate_pct"
echo "[runtime] availability.client_error_rate_pct=$client_error_rate_pct"
echo "[runtime] availability.server_error_rate_pct=$server_error_rate_pct"
echo "[runtime] performance.avg_latency_ms=$avg_latency_ms"
echo "[runtime] performance.p95_latency_ms=$p95_latency_ms"
echo "[runtime] stability.api_restart_count=$restart_count"
echo "[runtime] stability.api_oomkill_events=$oomkill_events"
echo "[runtime] capacity.api_ready_replicas=$ready_api"

fail=0

if [[ "$PROFILE" == "profile1" ]]; then
  # Core incident: OOM/restart behavior
  [[ "$oomkill_events" -eq 0 ]] || fail=1
  [[ "$restart_count" -le 0 ]] || fail=1
  [[ "$server_error_rate_bp" -le 500 ]] || fail=1   # <= 5.00%
elif [[ "$PROFILE" == "profile2" ]]; then
  # Related: CPU/latency degradation
  [[ "$p95_latency_ms" -le 900 ]] || fail=1
  [[ "$server_error_rate_bp" -le 100 ]] || fail=1   # <= 1.00%
elif [[ "$PROFILE" == "profile3" ]]; then
  # Related: sidecar-induced instability
  [[ "$oomkill_events" -eq 0 ]] || fail=1
  [[ "$restart_count" -le 0 ]] || fail=1
elif [[ "$PROFILE" == "profile4" ]]; then
  # Related: capacity shortfall under burst
  [[ "$ready_api" -ge 2 ]] || fail=1
  [[ "$p95_latency_ms" -le 900 ]] || fail=1
  [[ "$success_rate_bp" -ge 9800 ]] || fail=1       # >= 98.00%
else
  echo "unknown VERIFY_PROFILE: $PROFILE"
  exit 1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "[runtime] verdict=FAIL"
  exit 1
fi

echo "[runtime] verdict=PASS"
