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
