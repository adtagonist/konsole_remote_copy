#!/bin/bash

# ==============================================================================
# Konsole Remote Copy - Installer
# ==============================================================================

BIN_DIR="$HOME/.local/bin"
SCRIPT_NAME="konsole-remote-copy.sh"

echo "=== Konsole Remote Copy Installer"

# 1. Dependency Checks
echo "[1/3] Checking dependencies..."
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
    echo "Example (Kubuntu): sudo apt install qt6-tools procps libnotify-bin"
fi

# 2. Installation
echo "[2/3] Installing to $BIN_DIR..."
mkdir -p "$BIN_DIR"

if [ -f "$SCRIPT_NAME" ]; then
    cp "$SCRIPT_NAME" "$BIN_DIR/$SCRIPT_NAME"
    chmod +x "$BIN_DIR/$SCRIPT_NAME"
    echo "Success: Installed $SCRIPT_NAME to $BIN_DIR."
else
    echo "Error: $SCRIPT_NAME not found in current directory."
    exit 1
fi

# 3. Final steps
echo "[3/3] Final steps..."
echo ""
echo "Installation complete! To finish the setup:"
echo "1. Enable 'Allow terminal applications to handle clicks and drags' in Konsole (Mouse profile settings)."
echo "2. Add a Keyboard Shortcut in System Settings -> Shortcuts -> Add New -> Command or script."
echo "   Command path: $BIN_DIR/$SCRIPT_NAME"
echo ""
echo "Be sure to bind your shortcut to a key combination, then give it a test in a new terminal window."
echo "If nothing happens, `tail -f /var/log/syslog` and try to run it again.
