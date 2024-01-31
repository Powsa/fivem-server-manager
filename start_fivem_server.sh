#!/bin/bash

SCREEN_NAME="fivem-server"
COMMAND="./run.sh"
ALPINE_DIR="alpine"
RESOURCES_DIR="resources"
CONFIG_FILE="server.cfg"

# Check if all required directories and the config file exist
if [ ! -d "$ALPINE_DIR" ] || [ ! -d "$RESOURCES_DIR" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Either '$ALPINE_DIR' or '$RESOURCES_DIR' directories or '$CONFIG_FILE' file is missing."
    exit 1
fi

case "$1" in
    "start")
        # Check if the screen session is already running
        if screen -list | grep -q "$SCREEN_NAME"; then
            echo "Screen session '$SCREEN_NAME' is already running. Cannot start another instance."
        else
            # Start the screen session with the specified command
            screen -S "$SCREEN_NAME" -d -m "$COMMAND"
            echo "Screen session '$SCREEN_NAME' started with command: $COMMAND"
        fi
        ;;
    "stop")
        # Check if the screen session is running and stop it
        if screen -list | grep -q "$SCREEN_NAME"; then
            screen -S "$SCREEN_NAME" -X quit
            echo "Screen session '$SCREEN_NAME' has been stopped."
        else
            echo "Screen session '$SCREEN_NAME' is not currently running."
        fi
        ;;
    "status")
        # Check the status of the screen session
        if screen -list | grep -q "$SCREEN_NAME"; then
            echo "Screen session '$SCREEN_NAME' is currently active and running."
        else
            echo "Screen session '$SCREEN_NAME' is not currently running."
        fi
        ;;
    "attach")
        # Attach to the screen session if it's running, detach with Ctrl+A followed by D
        if screen -list | grep -q "$SCREEN_NAME"; then
            screen -r "$SCREEN_NAME"
        else
            echo "Screen session '$SCREEN_NAME' is not currently running."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|attach}"
        exit 1
        ;;
esac
