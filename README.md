# Konsole Remote Copy

This is a lightweight tool for KDE Konsole (Plasma 6) that allows you to copy file contents from a remote server or on your local machine, to your local system clipboard. It achieves this with **zero software required on the remote server**.

Why?

Because sometimes you just need to copy the contents of a complete file to the clipboard, you can't install additional software on the remote end, and you really don't feel like using cat to select and copy all the text. 

I am also hopeless at remembering commands, so I needed a way to trigger this with a keyboard shortcut.

This tool leverages the **OSC 52** terminal protocol. 
1. The local script is triggered by a keyboard shortcut.
2. It detects your active Konsole session and injects a "magic" command.
3. The remote shell executes this command, encoding the file contents into a terminal escape sequence.
4. Konsole interprets the sequence and updates your local system clipboard.

### Run the Installer
On your local KDE-based Linux machine, run:

./install.sh

This will check for dependencies and copy the script to your `~/.local/bin/` folder.

# Configure Konsole
You may need to enable this setting:
- Open Konsole.
- Go to **Settings** -> **Edit Current Profile**.
- Select the **Mouse** tab, then click on **Miscellaneous**.
- Tick **Allow terminal applications to handle clicks and drags**.

### Set up the Keyboard Shortcut
1. Open **System Settings** -> **Keyboard** -> **Shortcuts**.
2. Click **+ Add New**, **Command or Script...** and name it `Remote Copy` or whatever you like.
3. Set the command to: `/home/YOUR_USERNAME/.local/bin/konsole-remote-copy.sh`.
4. Assign a shortcut like `Meta+C`.

## Requirements
- **Local machine**: KDE Plasma 6, `qdbus6` (qt6-tools), `libnotify` (optional).
- **Remote machine**: Any server with `base64` (Standard on almost all Linux distributions).

## Troubleshooting
- **Nothing happens?** Verify that `qdbus6` is installed and that your shortcut points to the correct absolute path of the script.
- **Copy fails?** Ensure the "Allow terminal applications to set clipboard" setting is checked in the active Konsole profile.
- **Syslog** Run `tail -f /var/log/syslog` and monitor the output when you press your preferred keyboard shortcut. 
