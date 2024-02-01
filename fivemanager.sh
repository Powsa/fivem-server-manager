#!/bin/bash

# Function to check for required dependencies and offer to install them
check_dependencies() {
    local missing_deps=()
    for dep in git xz; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "The following packages are required but not installed: ${missing_deps[*]}"
        read -p "Would you like to install them now? (y/n): " answer
        if [[ "$answer" = "y" ]]; then
            sudo apt-get update && sudo apt-get install -y "${missing_deps[@]}"
            echo "Dependencies installed."
        else
            exit 1
        fi
    fi
}

# Function to create the server directory and setup the server
create_server() {
    check_dependencies

    read -p "Enter a name for your server (e.g., my-fivem-server): " server_name
    read -p "Enter the URL of the server build: " server_build_url

    local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    local server_directory="$script_dir/$server_name"
    
    echo "Creating server directory at $server_directory..."
    mkdir -p "$server_directory" || exit 1

    cd "$server_directory" || exit 1
    echo "Downloading server build from $server_build_url..."
    wget -q "$server_build_url" -O fx.tar.xz && tar xf fx.tar.xz

    local resources_directory="$server_directory/resources"
    echo "Creating resources directory..."
    mkdir -p "$resources_directory"

    local server_cfg_file="$server_directory/server.cfg"
    echo "Creating server.cfg file..."
    touch "$server_cfg_file"

    echo "Setup completed! Configure your server in $server_cfg_file"
    echo "To start your server, run this script again with 'start' option: $(basename "${BASH_SOURCE[0]}") start"
}

# Function to log messages with a timestamp
log_message() {
    local log_file="${server_directory}/server.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Function to manage the screen session
manage_screen() {
    local screen_name="$server_name"
    local command="./$(basename "${BASH_SOURCE[0]}") $1"

    case "$1" in
        "start")
            if screen -list | grep -q "\.$screen_name"; then
                echo "Screen session '$screen_name' is already running."
                log_message "Attempted to start screen session '$screen_name', but it is already running."
            else
                screen -S "$screen_name" -d -m $command
                echo "Started screen session '$screen_name' with command: $command"
                log_message "Started screen session '$screen_name' with command: $command"
            fi
            ;;
        "stop")
            if screen -list | grep -q "\.$screen_name"; then
                screen -S "$screen_name" -X quit
                echo "Stopped screen session '$screen_name'."
                log_message "Stopped screen session '$screen_name'."
            else
                echo "Screen session '$screen_name' is not running."
                log_message "Attempted to stop screen session '$screen_name', but it is not running."
            fi
            ;;
        "restart")
            if screen -list | grep -q "\.$screen_name"; then
                screen -S "$screen_name" -X quit
                echo "Stopping screen session '$screen_name' for restart."
                log_message "Stopping screen session '$screen_name' for restart."
            else
                echo "Screen session '$screen_name' is not running, starting it now."
                log_message "Screen session '$screen_name' was not running, starting it now."
            fi
            # Wait a bit to ensure the session has stopped
            sleep 2
            screen -S "$screen_name" -d -m $command
            echo "Restarted screen session '$screen_name' with command: $command"
            log_message "Restarted screen session '$screen_name' with command: $command"
            ;;
        "status")
            if screen -list | grep -q "\.$screen_name"; then
                echo "Screen session '$screen_name' is running."
                log_message "Checked status of screen session '$screen_name': running."
            else
                echo "Screen session '$screen_name' is not running."
                log_message "Checked status of screen session '$screen_name': not running."
            fi
            ;;
        "attach")
            if screen -list | grep -q "\.$screen_name"; then
                screen -r "$screen_name"
                log_message "Attached to screen session '$screen_name'."
            else
                echo "Screen session '$screen_name' is not running."
                log_message "Attempted to attach to screen session '$screen_name', but it is not running."
            fi
            ;;
        *)
            echo "Usage: $0 {create|start|stop|status|attach|restart}"
            log_message "Invalid command: $1"
            exit 1
            ;;
    esac
}

case "$1" in
    "create")
        create_server
        ;;
    "start" | "stop" | "status" | "attach" | "restart")
        manage_screen "$1"
        ;;
    *)
        echo "Usage: $0 {create|start|stop|status|attach|restart}"
        exit 1
        ;;
esac