#!/bin/bash

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
# Function to create a new server directory and configuration file
create_server() {
    read -p "Enter the desired server name: " server_name
    server_dir="$(dirname "$(realpath "$0")")"  # Set server_dir to the script's directory
    server_path="$server_dir/$server_name"
    
    if [ -d "$server_path" ]; then
        echo "Error: Server directory '$server_name' already exists."
        return
    fi

    mkdir -p "$server_path" && cd "$server_path"
    git clone https://github.com/citizenfx/cfx-server-data.git . && rm -rf .git
    echo "cfx-server-data cloned and cleaned."

    local base_url="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
    local build_url=$(curl -s "${base_url}" | grep -oP 'href="\K[^"]+fx.tar.xz' | head -1)
    local full_url="${base_url}${build_url}"

    echo "Downloading the latest FiveM build..."
    if curl -o "$server_path/fx.tar.xz" "$full_url"; then
        echo "Download successful."
        echo "Extracting the server build..."
        if tar -xvf "$server_path/fx.tar.xz" -C "$server_path"; then
            echo "Extraction successful."
            # Remove the fx.tar.xz file after successful extraction
            rm "$server_path/fx.tar.xz"
            echo "Removed the fx.tar.xz archive."

            # Additionally, remove the .gitignore file if it exists
            if [ -f "$server_path/.gitignore" ]; then
                rm "$server_path/.gitignore"
                echo "Removed the .gitignore file."
            fi

            # Create and populate the server.cfg file
            echo "Creating and populating server.cfg..."
            # Create and populate the server.cfg file with a static template
            cat > "$server_path/server.cfg" << EOF
# Only change the IP if you're using a server with multiple network interfaces, otherwise change the port only.
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

# These resources will start by default.
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap
ensure rconlog

# This allows players to use scripthook-based plugins such as the legacy Lambda Menu.
# Set this to 1 to allow scripthook. Do note that this does _not_ guarantee players won't be able to use external plugins.
sv_scriptHookAllowed 0

# Uncomment this and set a password to enable RCON. Make sure to change the password - it should look like rcon_password "YOURPASSWORD"
#rcon_password ""

# A comma-separated list of tags for your server.
# For example:
# - sets tags "drifting, cars, racing"
# Or:
# - sets tags "roleplay, military, tanks"
sets tags "default"

# A valid locale identifier for your server's primary language.
# For example "en-US", "fr-CA", "nl-NL", "de-DE", "en-GB", "pt-BR"
sets locale "root-AQ" 
# please DO replace root-AQ on the line ABOVE with a real language! :)

# Set an optional server info and connecting banner image url.
# Size doesn't matter, any banner sized image will be fine.
#sets banner_detail "https://url.to/image.png"
#sets banner_connecting "https://url.to/image.png"

# Set your server's hostname. This is not usually shown anywhere in listings.
sv_hostname "FXServer, but unconfigured"

# Set your server's Project Name
sets sv_projectName "My FXServer Project"

# Set your server's Project Description
sets sv_projectDesc "Default FXServer requiring configuration"

# Set Game Build (https://docs.fivem.net/docs/server-manual/server-commands/#sv_enforcegamebuild-build)
#sv_enforceGameBuild 2802

# Nested configs!
#exec server_internal.cfg

# Loading a server icon (96x96 PNG file)
#load_server_icon myLogo.png

# convars which can be used in scripts
set temp_convar "hey world!"

# Remove the `#` from the below line if you want your server to be listed as 'private' in the server browser.
# Do not edit it if you *do not* want your server listed as 'private'.
# Check the following url for more detailed information about this:
# https://docs.fivem.net/docs/server-manual/server-commands/#sv_master1-newvalue
#sv_master1 ""

# Add system admins
add_ace group.admin command allow # allow all commands
add_ace group.admin command.quit deny # but don't allow quit
add_principal identifier.fivem:1 group.admin # add the admin to the group

# enable OneSync (required for server-side state awareness)
set onesync on

# Server player slot limit (see https://fivem.net/server-hosting for limits)
sv_maxclients 48

# Steam Web API key, if you want to use Steam authentication (https://steamcommunity.com/dev/apikey)
# -> replace "" with the key
set steam_webApiKey ""

# License key for your server (https://keymaster.fivem.net)
sv_licenseKey changeme
EOF
            echo "server.cfg has been created and populated."
        else
            echo "Failed to extract the server build. Please check:" >&2
            echo "- File permissions" >&2
            echo "- Disk space" >&2
            echo "- Archive integrity: Run 'xz -t $server_path/fx.tar.xz' to test" >&2
            echo "- xz and tar availability: Ensure both are installed and support .xz files" >&2
            exit 1
        fi
    else
        echo "Failed to download the latest FiveM build."
        exit 1
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
    echo "6. Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1) create_server ;;
        2) start_server ;;
        3) stop_server ;;
        4) monitor_server ;;
        6) exit 0 ;;
        *) echo "Invalid choice." ;;
    esac
done
