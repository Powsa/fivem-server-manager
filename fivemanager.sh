#!/bin/bash

# Verwijder eventuele tijdelijke updatebestanden die zijn achtergelaten
rm -f temp_updated_fivemanager.sh

# Initialize an error message variable
errorMsg=""

# Define the required dependencies
dependencies=("git" "xz" "curl")

# Function to install a missing dependency
install_dependency() {
    local dependency="$1"
    echo "Installing $dependency..."
    if sudo apt-get update && sudo apt-get install -y "$dependency"; then
        echo "$dependency installed successfully."
    else
        echo "Failed to install $dependency. Please install it manually and try again."
        exit 1
    fi
}

# Loop through the dependencies and check if they are installed
for dependency in "${dependencies[@]}"; do
    if ! command -v "$dependency" &>/dev/null; then
        errorMsg="${errorMsg}Error: $dependency is not installed. Attempting to install it...\n"
        install_dependency "$dependency"
    fi
done

# Display error messages and exit if any checks failed
if [ ! -z "$errorMsg" ]; then
    printf "$errorMsg"
    exit 1
fi

# Function to create a screen session if it doesn't exist
create_screen_session() {
    if ! screen -ls | grep -q "FiveM"; then
        screen -S FiveM -dm bash
    fi
}

# Function to start the FiveM server
start_server() {
    # Get the directory where the script is located
    script_dir="$(dirname "$(realpath "$0")")"
    
    # List available servers for the user to choose
    available_servers=("$script_dir"/*)

    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found in the server directory. Cannot start any servers."
        return 1
    fi

    echo "Available servers:"
    for ((i=0; i<${#available_servers[@]}; i++)); do
        server_name=$(basename "${available_servers[$i]}")
        echo "$((i+1)). $server_name"
    done

    # Ask the user for their choice
    read -p "Enter the number of the server you want to start: " server_choice

    # Validate the user's choice
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi

    selected_server="${available_servers[$((server_choice-1))]}"
    
    # Create a screen session for the selected server and run the run.sh script within screen
    screen -dmS "fivem_server_$(basename "$selected_server")" bash -c "cd '$selected_server' && ./run.sh"

    echo "Started the server: $(basename "$selected_server")"
}


# Function to stop the FiveM server
stop_server() {
    screen -S FiveM -p 0 -X stuff "exit\n"
}

# Function to monitor the FiveM server's console output
monitor_server() {
    # Get the directory where the script is located
    script_dir="$(dirname "$(realpath "$0")")"
    
    # List available servers for the user to choose
    available_servers=("$script_dir"/*)

    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found in the server directory. Cannot monitor any servers."
        return 1
    fi

    echo "Available servers:"
    for ((i=0; i<${#available_servers[@]}; i++)); do
        server_name=$(basename "${available_servers[$i]}")
        echo "$((i+1)). $server_name"
    done

    # Ask the user for their choice
    read -p "Enter the number of the server you want to monitor: " server_choice

    # Validate the user's choice
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi

    selected_server="${available_servers[$((server_choice-1))]}"
    screen_name="fivem_server_$(basename "$selected_server")"
    
    # Attach to the selected server's screen session
    screen -r "$screen_name"
}

create_server() {
    read -p "Enter the desired server name: " server_name
    server_dir="$(pwd)"
    server_path="$server_dir/$server_name"

    if [ -d "$server_path" ]; then
        echo "Error: Server directory '$server_name' already exists."
        return
    fi

    echo "Creating directory $server_path..."
    mkdir -p "$server_path" && cd "$server_path" || { echo "Failed to create or access directory $server_path."; exit 1; }

    echo "Cloning cfx-server-data..."
    git clone https://github.com/citizenfx/cfx-server-data.git . && rm -rf .git || { echo "Failed to clone cfx-server-data repository."; exit 1; }

    local base_url="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
    echo "Fetching the latest FiveM build URL..."
    local build_url=$(curl -s "${base_url}" | grep -o 'href="[^"]\+fx.tar.xz"' | head -1 | cut -d '"' -f 2)
    if [ -z "$build_url" ]; then
        echo "Failed to obtain the build URL."
        exit 1
    fi

    local full_url="${base_url}${build_url}"
    full_url="${full_url/.\//}"

    echo "Downloading the FiveM build from: $full_url"
    download_result=$(curl -o "fx.tar.xz" "$full_url" 2>&1)
    echo "$download_result"
    if [ $? -ne 0 ]; then
        echo "Download failed. Check the above output for detailed information."
        exit 1
    else
        echo "Download successful."
    fi

    echo "Extracting the server build..."
    if tar -xvf "fx.tar.xz" -C "$server_path"; then
        echo "Extraction successful."
        rm "fx.tar.xz"
        echo "Removed the fx.tar.xz archive."
    else
        echo "Failed to extract the server build. Check file permissions, disk space, or archive integrity."
        exit 1
    fi

    echo "Creating and populating server.cfg from online source..."
    if curl -o "$server_path/server.cfg" "https://syslogine.cloud/docs/games/gta_v/pixxy/config.cfg"; then
        echo "server.cfg has been downloaded and populated."
    else
        echo "Failed to download server.cfg. Check the URL and internet connection."
        exit 1
    fi
}

# Function to update the script from GitHub
update_script() {
    echo "Updating the script..."
    if curl -sSf "https://raw.githubusercontent.com/Syslogine/fivem-server-manager/main/fivemanager.sh" -o "temp_updated_fivemanager.sh"; then
        echo "Download successful."
        if cp -f "temp_updated_fivemanager.sh" "$0"; then
            echo "Update successful. Restarting the script..."
            exec "$0" "$@"
        else
            echo "Failed to update the script."
        fi
        rm -f "temp_updated_fivemanager.sh"
    else
        echo "Failed to download the updated script. Please check your internet connection or try again later."
    fi
}

# Main menu
while true; do
    clear
    echo "FiveM Server Management Script"
    echo "-----------------------------"
    echo "1. Create a new server"
    echo "2. Start the server"
    echo "3. Stop the server"
    echo "4. Monitor the server console"
    echo "5. Update this script"
    echo "6. Exit"
    echo "-----------------------------"
    read -p "Enter your choice: " choice

    case $choice in
        1) create_server ;;
        2) start_server ;;
        3) stop_server ;;
        4) monitor_server ;;
        5) update_script ;;
        6 | "exit" | "stop") exit 0 ;;
        *) echo "Invalid choice." ;;
    esac
done

