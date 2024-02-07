#!/bin/bash

# Initialize an error message variable
errorMsg=""

# Define the required dependencies
dependencies=("git" "xz" "curl")

# Function to install a missing dependency
install_dependency() {
    local dependency="$1"
    while true; do
        echo "Attempting to install $dependency..."
        if sudo apt-get update && sudo apt-get install -y "$dependency"; then
            echo "$dependency installed successfully."
            break
        else
            echo "Failed to install $dependency."
            read -p "Do you want to retry (r), skip (s), or exit (e)? [r/s/e] " choice
            case $choice in
                r|R) echo "Retrying..." ;;
                s|S) echo "Skipping $dependency installation."
                     return 0 ;;
                e|E) echo "Exiting script."
                     exit 1 ;;
                *) echo "Invalid choice. Please enter r, s, or e." ;;
            esac
        fi
    done
}

# Loop through the dependencies and check if they are installed
for dependency in "${dependencies[@]}"; do
    if ! command -v "$dependency" &>/dev/null; then
        errorMsg="${errorMsg}Error: $dependency is not installed.\n"
        install_dependency "$dependency"
    fi
done

# Display error messages if any checks failed
if [ ! -z "$errorMsg" ]; then
    printf "$errorMsg"
    # Consider removing the exit here to allow the script to attempt running even if dependencies are missing,
    # or handle this more gracefully depending on which dependencies were skipped.
fi

# Function to create a screen session if it doesn't exist
create_screen_session() {
    if ! screen -ls | grep -q "FiveM"; then
        screen -S FiveM -dm bash
    fi
}

# Function to start the FiveM server
start_server() {
    script_dir="$(dirname "$(realpath "$0")")"
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
    read -p "Enter the number of the server you want to start: " server_choice
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi
    selected_server="${available_servers[$((server_choice-1))]}"
    screen -dmS "fivem_server_$(basename "$selected_server")" bash -c "cd '$selected_server' && ./run.sh"
    echo "Started the server: $(basename "$selected_server")"
}


# Function to list and stop FiveM server sessions
stop_server() {
    local sessions=$(screen -ls | grep 'fivem_server_' | awk '{print $1}')
    local session_array=($sessions)
    if [ ${#session_array[@]} -eq 0 ]; then
        echo "No active FiveM server sessions found."
        return 0
    fi
    echo "Active FiveM Server Sessions:"
    local count=1
    for session in "${session_array[@]}"; do
        echo "$count. $session"
        ((count++))
    done
    read -p "Enter the number of the server to stop (0 to cancel): " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -gt ${#session_array[@]} ]; then
        echo "Invalid choice. Operation cancelled."
        return 1
    fi
    if [ "$choice" -eq 0 ]; then
        echo "Operation cancelled by user."
        return 0
    fi
    local selected_session_index=$((choice-1))
    local selected_session=${session_array[$selected_session_index]}
    if screen -S "$selected_session" -X quit; then
        echo "Server $selected_session stopped successfully."
    else
        echo "Failed to stop server $selected_session."
    fi
}

# Function to monitor the FiveM server's console output
monitor_server() {
    script_dir="$(dirname "$(realpath "$0")")"
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
    read -p "Enter the number of the server you want to monitor: " server_choice
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi
    selected_server="${available_servers[$((server_choice-1))]}"
    screen_name="fivem_server_$(basename "$selected_server")"
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
    local script_name=$(basename "$0")
    local temp_script="temp_updated_$script_name"
    local backup_script="${script_name}.backup"
    local script_url="https://raw.githubusercontent.com/Syslogine/fivem-server-manager/main/$script_name"
    echo "Checking for updates..."
    if curl -sSf "$script_url" -o "$temp_script"; then
        if cmp -s "$temp_script" "$0"; then
            echo "No new updates available. You are using the latest version."
            rm -f "$temp_script"
            return 0
        else
            echo "Update available. Proceeding with the update..."
        fi
        echo "Backing up the current script to $backup_script..."
        if cp -f "$0" "$backup_script"; then
            echo "Backup created successfully."
        else
            echo "Failed to create backup. Update aborted."
            rm -f "$temp_script"
            return 1
        fi
        echo "Validating the downloaded script..."
        if grep -q "#!/bin/bash" "$temp_script"; then
            echo "Validation successful."
            echo "Updating the script..."
            if mv -f "$temp_script" "$0"; then
                echo "Update successful. Restarting the script..."
                chmod +x "$0"
                exec "$0"
            else
                echo "Failed to update the script. Attempting to restore from backup..."
                if cp -f "$backup_script" "$0"; then
                    echo "Restore successful. Please try updating again."
                else
                    echo "Critical error: Restore failed. Check your backup at $backup_script."
                fi
            fi
        else
            echo "Validation failed. Update aborted. Please check the script source."
            rm -f "$temp_script"
        fi
    else
        echo "Failed to download the updated script. Please check your internet connection or try again later."
    fi
}

# Function to display the main menu
display_menu() {
    echo "FiveM Server Management Script"
    echo "-----------------------------"
    echo "1. Create a new server"
    echo "2. Start the server"
    echo "3. Stop the server"
    echo "4. Monitor the server console"
    echo "5. Update this script"
    echo "6. Exit"
    echo "7. Debug Server"
    echo "-----------------------------"
}

# Function for handling invalid choices
handle_invalid_choice() {
    echo "Invalid choice: $1. Please try again."
}

# Debug function (Example)
debug_server() {
    echo "Debugging servers is not yet implemented."
}

# Main menu loop
while true; do
    clear
    display_menu
    read -p "Enter your choice: " choice

    case $choice in
        1) create_server ;;
        2) start_server ;;
        3) stop_server ;;
        4) monitor_server ;;
        5) update_script ;;
        6) echo "Exiting the script. Goodbye!"; exit 0 ;;
        7) debug_server ;;
        *) handle_invalid_choice "$choice" ;;
    esac
    # Wait for user acknowledgment before clearing the screen and showing the menu again
    read -p "Press enter to continue..."
done
