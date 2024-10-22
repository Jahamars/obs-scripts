#!/bin/bash

# Function to prompt for input
prompt() {
    read -p "$1: " input
    echo "$input"
}

# Get user inputs
MODE=$(prompt "Choose mode (1: Send, 2: Receive)")
LOCAL_PATH=$(prompt "Enter the local directory path")
REMOTE_PATH=$(prompt "Enter the remote directory path")
REMOTE_USER=$(prompt "Enter remote username")
REMOTE_HOST=$(prompt "Enter remote host (IP or hostname)")

# Remove trailing slashes
LOCAL_PATH=${LOCAL_PATH%/}
REMOTE_PATH=${REMOTE_PATH%/}

# Execute rsync based on the mode
if [ "$MODE" -eq 1 ]; then
    echo "Sending files to remote host..."
    rsync -avz --progress "$LOCAL_PATH/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"
elif [ "$MODE" -eq 2 ]; then
    echo "Receiving files from remote host..."
    rsync -avz --progress "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/" "$LOCAL_PATH/"
else
    echo "Invalid mode. Use '1' for sending or '2' for receiving."
    exit 1
fi

echo "Operation completed."
