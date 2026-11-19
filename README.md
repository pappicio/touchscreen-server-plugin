# Touchscreen Server

OpenCreator plugin for the FlashForge Creator 5.

The plugin copies `scripts/touchscreen-server.py` to:

`/usr/data/opencreator/scripts/touchscreen-server.py`

The script is launched by **Script Runner**. It is not registered as a separate OpenCreator service.

## Requirements

- OpenCreator
- Script Runner installed at `/usr/data/opencreator/plugins/script-runner`
- Creator 5 framebuffer at `/dev/fb0`
- Touch input device at `/dev/input/event2`

## Usage

After installation, restart Script Runner (or reboot the printer). Open:

`http://PRINTER_IP:8085/`

The server provides a live framebuffer image and forwards taps/swipes to the touchscreen input device.

## Install / uninstall

The install hook verifies that Script Runner is installed and copies the Python script into the shared scripts directory.

The uninstall hook stops the server using its PID file and removes only `touchscreen-server.py`. It does not remove Script Runner or other user scripts.

## Network access

The HTTP server listens on `0.0.0.0:8085` and has no authentication. Use it only on a trusted network; do not expose this port to the internet.
