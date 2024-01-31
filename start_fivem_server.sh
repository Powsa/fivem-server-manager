#!/bin/bash

SCREEN_NAME="fivem-server"
COMMAND="./run.sh"

case "$1" in
    "start")
        # Check if the screen session is already running
        if screen -list | grep -q "$SCREEN_NAME"; then
            echo "Screen session '$SCREEN_NAME' is already running."
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
            echo "Screen session '$SCREEN_NAME' stopped."
        else
            echo "Screen session '$SCREEN_NAME' is not running."
        fi
        ;;
    "status")
        # Check the status of the screen session
        if screen -list | grep -q "$SCREEN_NAME"; then
            echo "Screen session '$SCREEN_NAME' is running."
        else
            echo "Screen session '$SCREEN_NAME' is not running."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
