
#!/opt/bin/sh
set -eu

PLUGIN_MANIFEST="/usr/data/opencreator/plugins/script-runner/opencreator-plugin.json"
SCRIPTS_DIR="/usr/data/opencreator/scripts"
PLUGIN_DIR="${OC_PLUGIN_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}"
SOURCE="$PLUGIN_DIR/scripts/touchscreen-server.py"
DEST="$SCRIPTS_DIR/touchscreen-server.py"

echo "[Touchscreen Server] Checking Script Runner..."

if [ ! -f "$PLUGIN_MANIFEST" ] || ! grep -q '"id"[[:space:]]*:[[:space:]]*"script-runner"' "$PLUGIN_MANIFEST"; then
    echo "[Touchscreen Server] ERROR: Script Runner is not installed."
    exit 1
fi

if [ ! -f "$SOURCE" ]; then
    echo "[Touchscreen Server] ERROR: touchscreen-server.py not found: $SOURCE"
    exit 1
fi

mkdir -p "$SCRIPTS_DIR"
cp "$SOURCE" "$DEST"
chmod 644 "$DEST"

echo "[Touchscreen Server] Installed $DEST"
echo "[Touchscreen Server] Script Runner will launch it on its next start."

PRINTER_IP="$(ip -4 route get 1.1.1.1 2>/dev/null |
    awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"

if [ -z "$PRINTER_IP" ]; then
    PRINTER_IP="$(ip -4 addr show scope global 2>/dev/null |
        awk '/inet / {sub(/\/.*/, "", $2); print $2; exit}')"
fi

echo
if [ -n "$PRINTER_IP" ]; then
    echo "[Touchscreen Server] Installation completed!"
    echo
    echo "To connect and tap on remote GrumpyScreen, go to:"
    echo "http://${PRINTER_IP}:8085"
else
    echo "[Touchscreen Server] Installation completed!"
    echo "[Touchscreen Server] Unable to detect printer IP."
fi

exit 0
