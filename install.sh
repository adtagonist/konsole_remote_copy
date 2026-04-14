#!/bin/bash

BIN_DIR="$HOME/.local/bin"
SCRIPT_NAME="konsole-remote-copy.sh"

echo "=== Konsole Remote Copy: Installer ==="

DEPS=("qdbus6" "pgrep" "notify-send" "base64")
MISSING=()

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING+=("$dep")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Warning: The following dependencies are missing: ${MISSING[*]}"
    echo "Please install them via your package manager."
    echo "Example (Ubuntu): sudo apt install qt6-tools procps libnotify-bin"
fi

mkdir -p "$BIN_DIR"

if [ -f "$SCRIPT_NAME" ]; then
    cp "$SCRIPT_NAME" "$BIN_DIR/$SCRIPT_NAME"
    chmod +x "$BIN_DIR/$SCRIPT_NAME"
    echo "Success: Installed $SCRIPT_NAME to $BIN_DIR."
else
    echo "Error: $SCRIPT_NAME not found in current directory."
    exit 1
fi

echo ""
echo "Installation complete! To finish the setup:"
echo "1. Enable 'Allow terminal applications to set clipboard' in Konsole (Advanced profile settings)."
echo "2. Add a Keyboard Shortcut in System Settings -> Shortcuts -> Commands."
echo "   Command path: $BIN_DIR/$SCRIPT_NAME"
echo ""
echo "Try Meta+C to test it once the shortcut is bound!"
