#!/usr/bin/env bash
# ==============================================================================
# persistent-port-forward.sh
# Starts and auto-restarts kubectl port-forwards for Spanner Omni
# Runs in foreground — use Ctrl+C to stop
# ==============================================================================

NAMESPACE="spanner-omni"
DB_LOCAL_PORT=15000
DB_REMOTE_PORT=15000
CONSOLE_LOCAL_PORT=15026
CONSOLE_REMOTE_PORT=15026

echo "🚀 Starting persistent port-forwards for Spanner Omni..."
echo "   DB endpoint:      http://localhost:${DB_LOCAL_PORT}"
echo "   Console UI:       http://localhost:${CONSOLE_LOCAL_PORT}"
echo "   Press Ctrl+C to stop."
echo ""

cleanup() {
  echo ""
  echo "Stopping port-forwards..."
  kill "$PF_DB_PID" "$PF_CONSOLE_PID" 2>/dev/null
  exit 0
}
trap cleanup INT TERM

while true; do
  # Start DB port-forward
  kubectl port-forward svc/spanner -n "$NAMESPACE" \
    "${DB_LOCAL_PORT}:${DB_REMOTE_PORT}" > /tmp/pf-db.log 2>&1 &
  PF_DB_PID=$!

  # Start Console port-forward
  kubectl port-forward svc/spanner-omni-console -n "$NAMESPACE" \
    "${CONSOLE_LOCAL_PORT}:${CONSOLE_REMOTE_PORT}" > /tmp/pf-console.log 2>&1 &
  PF_CONSOLE_PID=$!

  echo "[$(date '+%H:%M:%S')] ✅ Port-forwards started (DB PID=$PF_DB_PID, Console PID=$PF_CONSOLE_PID)"

  # Wait until one of the processes exits
  wait "$PF_DB_PID" "$PF_CONSOLE_PID"

  echo "[$(date '+%H:%M:%S')] ⚠️  Port-forward dropped. Restarting in 3s..."
  kill "$PF_DB_PID" "$PF_CONSOLE_PID" 2>/dev/null
  sleep 3
done
