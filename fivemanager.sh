#!/bin/bash

# Function to log messages with a timestamp
log_message() {
    local log_file="${server_directory}/server.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

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
    server_directory="$script_dir/$server_name"
    
    echo "Creating server directory at $server_directory..."
    mkdir -p "$server_directory" || exit 1

    cd "$server_directory" || exit 1
    echo "Downloading server build from $server_build_url..."
    wget -q "$server_build_url" -O fx.tar.xz && tar xf fx.tar.xz

    local resources_directory="$server_directory/resources"
    echo "Creating resources directory..."
    mkdir -p "$resources_directory"

    local server_cfg_file="$server_directory/server.cfg"
    touch "$server_cfg_file"

    echo "Setup completed! Configure your server in $server_cfg_file"
    log_message "Server setup completed for $server_name."
}

# Function to manage the screen session
manage_screen() {
    local screen_name="$server_name"
    local command="bash -c './run.sh +exec server.cfg'"

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
            manage_screen stop
            sleep 2
            manage_screen start
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
        *)
            echo "Invalid command: $1"
            log_message "Invalid command: $1"
            exit 1
            ;;
    esac
}

# Function to display an interactive menu
show_menu() {
    while true; do
        clear
        echo "FiveM Server Management"
        echo "1. Create Server"
        echo "2. Start Server"
        echo "3. Stop Server"
        echo "4. Restart Server"
        echo "5. Server Status"
        echo "6. Exit"
        echo ""
        read -p "Enter choice [1-6]: " choice

        case $choice in
            1) create_server ;;
            2) manage_screen start ;;
            3) manage_screen stop ;;
            4) manage_screen restart ;;
            5) manage_screen status ;;
            6) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please enter a number between 1 and 6."; read -n 1 ;;
        esac
    done
}

# Start the script with the menu
show_menu
