#!/bin/bash

# Function to check for required dependencies
check_dependencies() {
    local missing_deps=()
    for dep in git xz; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: The following packages are required but not installed: ${missing_deps[*]}"
        exit 1
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
    cat <<EOL > "$server_cfg_file"
# Your server configuration file.
# Customize as needed.
# sv_licenseKey "your_license_key_here"
EOL

    echo "Setup completed! Configure your server in $server_cfg_file"
    echo "To start your server, run this script again with 'start' option: $(basename "${BASH_SOURCE[0]}") start"
}


# Function to manage the screen session
manage_screen() {
    local screen_name="$server_name"
    local command="./$(basename "${BASH_SOURCE[0]}") $1"

    case "$1" in
        "start")
            if screen -list | grep -q "\.$screen_name"; then
                echo "Screen session '$screen_name' is already running."
            else
                screen -S "$screen_name" -d -m $command
                echo "Started screen session '$screen_name' with command: $command"
            fi
            ;;
        "stop")
            if screen -list | grep -q "\.$screen_name"; then
                screen -S "$screen_name" -X quit
                echo "Stopped screen session '$screen_name'."
            else
                echo "Screen session '$screen_name' is not running."
            fi
            ;;
        "status")
            if screen -list | grep -q "\.$screen_name"; then
                echo "Screen session '$screen_name' is running."
            else
                echo "Screen session '$screen_name' is not running."
            fi
            ;;
        "attach")
            if screen -list | grep -q "\.$screen_name"; then
                screen -r "$screen_name"
            else
                echo "Screen session '$screen_name' is not running."
            fi
            ;;
        *)
            echo "Usage: $0 {create|start|stop|status|attach}"
            exit 1
            ;;
    esac
}

case "$1" in
    "create")
        create_server
        ;;
    "start" | "stop" | "status" | "attach")
        manage_screen "$1"
        ;;
    *)
        echo "Usage: $0 {create|start|stop|status|attach}"
        exit 1
        ;;
esac
