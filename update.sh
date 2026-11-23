
#!/opt/bin/sh
set -eu

PLUGIN_DIR="${OC_PLUGIN_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}"

echo "[Touchscreen Server] Updating native plugin..."

exec /opt/bin/sh "$PLUGIN_DIR/install.sh" --update
