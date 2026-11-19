#!/opt/bin/sh
set -eu
PID_FILE="/tmp/oc-touchscreen-server.pid"
SCRIPT="/usr/data/opencreator/scripts/touchscreen-server.py"

echo "[Touchscreen Server] Stopping touchscreen server..."
if [ -f "$PID_FILE" ]; then
    PID="$(cat "$PID_FILE" 2>/dev/null || true)"
    case "$PID" in
        ''|*[!0-9]*) PID="" ;;
    esac
    if [ -n "$PID" ] && [ -r "/proc/$PID/cmdline" ]; then
        CMDLINE="$(tr '\000' ' ' < "/proc/$PID/cmdline" 2>/dev/null || true)"
        case "$CMDLINE" in
            *"$SCRIPT"*) kill -TERM "$PID" 2>/dev/null || true ;;
        esac
        COUNT=0
        while [ "$COUNT" -lt 5 ] && kill -0 "$PID" 2>/dev/null; do
            sleep 1
            COUNT=$((COUNT + 1))
        done
        if kill -0 "$PID" 2>/dev/null; then
            CMDLINE="$(tr '\000' ' ' < "/proc/$PID/cmdline" 2>/dev/null || true)"
            case "$CMDLINE" in
                *"$SCRIPT"*) kill -KILL "$PID" 2>/dev/null || true ;;
            esac
        fi
    fi
    rm -f "$PID_FILE"
fi
rm -f "$SCRIPT"
echo "[Touchscreen Server] Removed its script. Other user scripts were left untouched."
