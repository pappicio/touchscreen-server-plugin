
#!/opt/bin/sh
set -eu

PLUGIN_DIR="${OC_PLUGIN_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}"

SOURCE="$PLUGIN_DIR/scripts/touchscreen-server.py"
LAUNCHER="$PLUGIN_DIR/scripts/touchscreen-server.sh"

echo "[Touchscreen Server] Checking native plugin..."

if [ ! -f "$SOURCE" ]; then
    echo "[Touchscreen Server] ERROR: touchscreen-server.py not found."
    exit 1
fi

if [ ! -f "$LAUNCHER" ]; then
    echo "[Touchscreen Server] ERROR: touchscreen-server.sh not found."
    exit 1
fi

# Remove only the legacy Script Runner copy.
rm -f /usr/data/opencreator/scripts/touchscreen-server.py

PRINTER_IP="$(ip -4 route get 1.1.1.1 2>/dev/null |
    awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"

if [ -z "$PRINTER_IP" ]; then
    PRINTER_IP="$(ip -4 addr show scope global 2>/dev/null |
        awk '/inet / {sub(/\/.*/, "", $2); print $2; exit}')"
fi

echo
echo "[Touchscreen Server] Installation completed."

if [ -n "$PRINTER_IP" ]; then
    echo
    echo "Connect to the touchscreen server at:"
    echo "http://${PRINTER_IP}:8085"
else
    echo "[Touchscreen Server] Unable to detect printer IP."
fi

exit 0
