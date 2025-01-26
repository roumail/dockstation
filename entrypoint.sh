#!/bin/bash
set -e

PLUGINS_FILE="/root/.vim/custom/plug.vim"

if [ -f "$PLUGINS_FILE" ]; then
    echo "Found $PLUGINS_FILE. Installing Vim plugins..."
    # Run vim-plug in headless mode to install plugins
    # vim -E: Enables "Ex mode," which is non-interactive.
    # </dev/null: Prevents Vim from waiting for input during the build.
    # Ensure the container installs plugins into the host-mounted directory at runtime
    vim -E -u "$PLUGINS_FILE" +PlugInstall +qall </dev/null || {
        echo "Vim plugin installation failed!" >&2
        # Commented out so we can at least launch the container
        # exit 1
    }
else
    echo "Vim initialization file not found at $PLUGINS_FILE. Skipping plugin installation."
fi

# Launch a Bash session to keep the container running
exec /bin/bash
