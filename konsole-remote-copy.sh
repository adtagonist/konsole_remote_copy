#!/bin/bash
QDBUS=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)
SERVICE=""
SESSION_PATH=""

# Find the focused Konsole window using xargs to trim spaces from the service name
for s in $($QDBUS | grep 'org.kde.konsole' | xargs); do
    # Scan for any Window path
    for path in $($QDBUS "$s" | grep -E '^/Windows/|^/konsole/MainWindow_'); do
        # Check if THIS specific window is active/focused
        IS_ACTIVE=$($QDBUS "$s" "$path" org.qtproject.Qt.QWidget.isActiveWindow 2>/dev/null)
        
        if [ "$IS_ACTIVE" == "true" ]; then
            SERVICE="$s"
            # Get the numeric ID of the active session
            SESSION_ID=$($QDBUS "$SERVICE" "$path" currentSession 2>/dev/null)
            
            if [[ "$SESSION_ID" =~ ^[0-9]+$ ]]; then
                SESSION_PATH="/Sessions/$SESSION_ID"
                break 2
            fi
        fi
    done
done

# Fallback: If focus detection fails, use the last service found
if [ -z "$SERVICE" ] || [ -z "$SESSION_PATH" ]; then
    SERVICE=$($QDBUS | grep 'org.kde.konsole' | xargs | awk '{print $NF}')
    SESSION_PATH="/Sessions/1"
fi

if [ -n "$SERVICE" ] && [ -n "$SESSION_PATH" ]; then
    CMD='read -r -p "File to copy: " f && [ -f "$f" ] && printf "\033]52;c;%s\a" "$(base64 < "$f" | tr -d '"'"'\n'"'"')" && printf "\n[Copied: %s]\n" "$f"'
    $QDBUS "$SERVICE" "$SESSION_PATH" sendText "$CMD"$'\n'
else
    notify-send "Remote Copy" "Error: Could not find your Konsole session."
fi
