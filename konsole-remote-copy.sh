#!/bin/bash

QDBUS=$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)
BUSCTL=$(command -v busctl)

[ -z "$QDBUS" ] && exit 1

ACTIVE_PID=""

# Find Active PID (Wayland/KDE) - Method A: kdotool (fastest if installed)
if command -v kdotool &> /dev/null; then
    ACTIVE_PID=$(kdotool getactivewindow getwindowpid 2>/dev/null)
fi

# Method B: KWin Scripting (fallback method)
if [ -z "$ACTIVE_PID" ]; then
    SCRIPT_NAME="konsole_remote_copy_focus"
    TMP_JS="/tmp/${SCRIPT_NAME}.js"
    echo "print('KONSOLE_FOCUS_PID:' + workspace.activeWindow.pid)" > "$TMP_JS"
    
    $QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$SCRIPT_NAME" &>/dev/null
    SCRIPT_ID=$($QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$TMP_JS" "$SCRIPT_NAME" 2>/dev/null)
    
    if [[ "$SCRIPT_ID" =~ ^[0-9]+$ ]]; then
        $QDBUS org.kde.KWin "/Scripting/Script$SCRIPT_ID" org.kde.kwin.Script.run &>/dev/null
        $QDBUS org.kde.KWin "/Scripting/Script$SCRIPT_ID" org.kde.kwin.Script.stop &>/dev/null
        sleep 0.5
        # Robustly extract PID from ALL user logs
        ACTIVE_PID=$(journalctl --user --since "10 seconds ago" --output=cat 2>/dev/null | sed -n 's/.*KONSOLE_FOCUS_PID:\([0-9]*\).*/\1/p' | tail -n 1)
    fi
    rm -f "$TMP_JS"
fi

SERVICE=""
SESSIONS=()

if [[ "$ACTIVE_PID" =~ ^[0-9]+$ ]]; then
    SERVICE="org.kde.konsole-$ACTIVE_PID"
    
    if $QDBUS "$SERVICE" &>/dev/null; then
        for win in $($QDBUS "$SERVICE" 2>/dev/null | grep "/Windows/"); do
            SID=$($QDBUS "$SERVICE" "$win" org.kde.konsole.Window.currentSession 2>/dev/null)
            [[ "$SID" =~ ^[0-9]+$ ]] && SESSIONS+=("/Sessions/$SID")
        done
        
        if [ ${#SESSIONS[@]} -eq 0 ]; then
            SESSIONS+=("/Sessions/1")
        fi
    else
        SERVICE=""
    fi
fi

if [ -n "$SERVICE" ]; then
    UNIQUE_SESSIONS=($(echo "${SESSIONS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    
    # Stealth Multi-Line Clear (Clears 4 lines above the prompt to handle wrapping)
    CLEAR='\r\e[2K\e[F\e[2K\e[F\e[2K\e[F\e[2K\r'
    
    # Prompt and Success formatting
    P_FMT='\e[1;36mFile to copy: \e[0m'
    S_FMT='\e[1;32m[Copied: %s]\e[0m'
    
    # The Payload
    # Note: Leading space prevents history, $CLEAR hides wrapped lines in small windows.
    CMD=" printf \"$CLEAR\"; read -er -p \"\$(printf \"$P_FMT\")\" f && [ -f \"\$f\" ] && printf \"\x1b]52;c;%s\x07\" \"\$(base64 <\"\$f\" | tr -d '\\n')\" && printf \"\\n$S_FMT\\n\" \"\$f\""
    
    for session in "${UNIQUE_SESSIONS[@]}"; do
        if [ -n "$BUSCTL" ]; then
            # busctl is more robust for injection in KF6
            $BUSCTL --user call "$SERVICE" "$session" org.kde.konsole.Session sendText s "$CMD"$'\n' &>/dev/null
        else
            $QDBUS "$SERVICE" "$session" org.kde.konsole.Session.sendText "$CMD"$'\n' &>/dev/null
        fi
    done
else
    # Fallback finding by SSH process name
    PROMPT='$(printf "\e[1;36mFile to copy: \e[0m")'
    SUCCESS='\e[1;32m[Copied: %s]\e[0m'
    CMD=" printf \"\r\e[A\e[2K\r\"; read -er -p \"$PROMPT\" f && [ -f \"\$f\" ] && printf \"\x1b]52;c;%s\x07\" \"\$(base64 <\"\$f\" | tr -d '\\n')\" && printf \"\\n$SUCCESS\\n\" \"\$f\""
    
    for s in $($QDBUS | grep 'org.kde.konsole' | xargs); do
        PID=$(echo "$s" | cut -d- -f2)
        if [[ "$PID" =~ ^[0-9]+$ ]] && pgrep -P "$PID" ssh &>/dev/null; then
            if [ -n "$BUSCTL" ]; then
                $BUSCTL --user call "$s" /Sessions/1 org.kde.konsole.Session sendText s "$CMD"$'\n' &>/dev/null
            else
                $QDBUS "$s" /Sessions/1 org.kde.konsole.Session.sendText "$CMD"$'\n' &>/dev/null
            fi
            exit 0
        fi
    done
    notify-send "Remote Copy" "Error: Could not identify your active Konsole session."
fi
