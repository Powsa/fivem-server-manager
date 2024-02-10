#!/bin/bash

errorMsg=""
dependencies=("git" "xz" "curl" "unzip")

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

for dependency in "${dependencies[@]}"; do
    if ! command -v "$dependency" &>/dev/null; then
        errorMsg="${errorMsg}Error: $dependency is not installed.\n"
        install_dependency "$dependency"
    fi
done

if [ ! -z "$errorMsg" ]; then
    printf "$errorMsg"
fi

create_screen_session() {
    if ! screen -ls | grep -q "FiveM"; then
        screen -S FiveM -dm bash
    fi
}

start_server() {
    echo -e "${YELLOW}Fetching list of available servers...${NC}"
    script_dir="$(dirname "$(realpath "$0")")"
    available_servers=()
    for dir in "$script_dir"/*/; do
        if [ -f "${dir}run.sh" ]; then
            available_servers+=("$dir")
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found in the server directory with a run.sh script. Cannot start any servers."
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
    server_name=$(basename "${selected_server}")
    screen_name="$server_name"
    echo "Select the start method for the server:"
    echo "1. Standard start (run.sh)"
    echo "2. Start with server.cfg (run.sh +exec server.cfg)"
    read -p "Option [1-2]: " start_option
    case "$start_option" in
        2) start_cmd="./run.sh +exec server.cfg"
            if grep -qE '^\s*sv_licenseKey\s+changeme\s*$' "${selected_server}/server.cfg"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Warning: sv_licenseKey not set properly in server.cfg." >> "${selected_server}server.log"
            fi
           ;;
        *) start_cmd="./run.sh"
           ;;
    esac
    echo "Starting the server: $server_name"
    screen -dmS "$screen_name" bash -c "cd '$selected_server' && $start_cmd"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Server '$server_name' started with command: '$start_cmd'." >> "${selected_server}server.log"
    echo "Server start event logged in $server_name/server.log."
}

stop_server() {
    local sessions=$(screen -ls | awk '/\.testserver\t/ {print $1}' | sed 's/.*\.//')
    local session_array=($sessions)
    if [ ${#session_array[@]} -eq 0 ]; then
        echo "No active FiveM server sessions found."
        return 0
    fi
    echo "Active FiveM Server Sessions:"
    for i in "${!session_array[@]}"; do
        echo "$((i+1)). ${session_array[$i]}"
    done
    read -p "Enter the number of the server to stop (0 to cancel): " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#session_array[@]} ]; then
        echo "Invalid choice. Operation cancelled."
        return 1
    fi
    if [ "$choice" -eq 0 ]; then
        echo "Operation cancelled by user."
        return 0
    fi
    local selected_server_name=${session_array[$((choice-1))]}
    if screen -S "$selected_server_name" -X quit; then
        echo "Server $selected_server_name stopped successfully."
        local script_dir="$(dirname "$(realpath "$0")")"
        local log_path="$script_dir/$selected_server_name/server.log"
        if [[ -f "$log_path" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Server '$selected_server_name' stopped." >> "$log_path"
            echo "Server stop event logged in $selected_server_name/server.log"
        else
            echo "Failed to log stop event: $log_path does not exist."
        fi
    else
        echo "Failed to stop server $selected_server_name."
    fi
}

monitor_server() {
    script_dir="$(dirname "$(realpath "$0")")"
    available_servers=()
    for dir in "$script_dir"/*/; do
        if [ -f "${dir}run.sh" ]; then
            available_servers+=("$dir")
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found in the server directory. Cannot monitor any servers."
        return 1
    fi
    echo "Available servers:"
    for ((i=0; i<${#available_servers[@]}; i++)); do
        server_name=$(basename "${available_servers[$i]}")
        if [[ $server_name != "fivemanager.sh" ]]; then
            echo "$((i+1)). $server_name"
        fi
    done
    read -p "Enter the number of the server you want to monitor: " server_choice
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi
    selected_server="${available_servers[$((server_choice-1))]}"
    server_name=$(basename "${selected_server%/}")
    screen_name="$server_name"
    echo "Now monitoring $server_name. To detach and return to the menu, press 'Ctrl+A' followed by 'D'."
    read -p "Press any key to continue..." -n 1 -s
    screen -r "$screen_name"
    echo "You have successfully detached from the $server_name session."
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
    touch "$server_path/server.log" || { echo "Failed to create server.log file."; exit 1; }
    if curl -o "$server_path/server.cfg" "https://syslogine.cloud/docs/games/gta_v/pixxy/config.cfg"; then
        echo "server.cfg has been downloaded and populated."
    else
        echo "Failed to download server.cfg. Check the URL and internet connection."
        exit 1
    fi
}

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

# Debug function
debug_server() {
    echo "Select a server to debug:"
    script_dir="$(dirname "$(realpath "$0")")"
    available_servers=()
    for dir in "$script_dir"/*/; do
        if [ -f "${dir}run.sh" ]; then
            available_servers+=("$dir")
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found in the server directory with a run.sh script. Cannot debug any servers."
        return 1
    fi
    for ((i=0; i<${#available_servers[@]}; i++)); do
        server_name=$(basename "${available_servers[$i]}")
        echo "$((i+1)). $server_name"
    done
    read -p "Enter the number of the server you want to debug: " server_choice
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi
    selected_server="${available_servers[$((server_choice-1))]}"
    server_name=$(basename "${selected_server}")
    echo "Debugging server: $server_name"
    if screen -list | grep -q "fivem_server_$server_name"; then
        echo "Server is currently running."
    else
        echo "Server is not running."
    fi
    local log_file="${selected_server}server.log"
    if [ -f "$log_file" ]; then
        echo "Last 10 lines of the server log:"
        tail -n 10 "$log_file"
    else
        echo "Server log file not found."
        read -p "Would you like to create one? (y/N): " create_choice
        if [[ $create_choice =~ ^[Yy]$ ]]; then
            # Attempt to create an empty log file
            touch "$log_file" && echo "Log file created at $log_file" || echo "Failed to create log file."
        else
            echo "Not creating a log file."
        fi
    fi
}

update_txAdmin() {
    echo "Fetching the latest txAdmin release information..."
    available_servers=()
    script_dir="$(dirname "$(realpath "$0")")"
    for server_dir in "$script_dir"/*; do
        if [ -d "$server_dir" ] && [ -f "$server_dir/run.sh" ]; then
            available_servers+=("$server_dir")
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found. Please ensure server directories are present and contain a run.sh script."
        return 1
    fi
    echo "Available servers for txAdmin update:"
    for i in "${!available_servers[@]}"; do
        echo "$((i+1)). $(basename "${available_servers[$i]}")"
    done
    read -p "Enter the number of the server you want to update txAdmin for: " server_choice
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi
    selected_server="${available_servers[$((server_choice-1))]}"
    txAdmin_dir="${selected_server}/alpine/opt/cfx-server/citizen/system_resources/monitor"
    release_info=$(curl -s https://api.github.com/repos/tabarra/txAdmin/releases/latest)
    download_url=$(echo "$release_info" | jq -r '.assets[] | select(.name == "monitor.zip") | .browser_download_url')
    if [ -z "$download_url" ]; then
        echo "Failed to find monitor.zip in the latest release."
        return 1
    fi
    echo "Downloading monitor.zip from $download_url..."
    curl -L "$download_url" -o monitor.zip
    if ! command -v unzip &> /dev/null; then
        echo "The 'unzip' utility is required but not installed. Please install it using your package manager."
        return 1
    fi
    temp_dir=$(mktemp -d)
    echo "Extracting monitor.zip to temporary directory..."
    unzip monitor.zip -d "$temp_dir"
    rm monitor.zip
    echo "Updating txAdmin monitor in $txAdmin_dir..."
    rm -rf "$txAdmin_dir/*"
    mkdir "$txAdmin_dir/"
    mv "$temp_dir"/* "$txAdmin_dir/"
    rm -rf "$temp_dir"
    echo "txAdmin update process complete."
}

# Function to delete a server
delete_server() {
    script_dir="$(dirname "$(realpath "$0")")"
    available_servers=()
    echo "Available servers to delete:"
    for dir in "$script_dir"/*/; do
        if [ -d "$dir" ]; then
            server_name=$(basename "$dir")
            available_servers+=("$server_name")
            echo "${#available_servers[@]}. $server_name"
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found. Nothing to delete."
        return 1
    fi
    read -p "Enter the number of the server you want to delete (or '0' to cancel): " server_choice
    if [ "$server_choice" -eq 0 ]; then
        echo "Deletion cancelled."
        return 0
    fi
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi
    selected_server="${available_servers[$((server_choice-1))]}"
    read -p "Are you sure you want to delete $selected_server? This action cannot be undone. (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -rf "$script_dir/$selected_server"
        echo "$selected_server has been deleted."
    else
        echo "Deletion cancelled."
    fi
}

monitor_server_performance() {
    echo -e "${YELLOW}Gathering comprehensive system performance metrics...${NC}"
    
    CPU_MODEL=$(lscpu | grep "Model name" | awk -F: '{print $2}' | sed -e 's/^[[:space:]]*//')
    echo -e "${GREEN}CPU Model:${NC} $CPU_MODEL"

    CPU_CORES=$(nproc)
    echo -e "${GREEN}CPU Core Count:${NC} ${CPU_CORES}"
    
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
    echo -e "${GREEN}CPU Usage:${NC} ${CPU_USAGE}"
    
    TOTAL_RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024 " MB"}')
    echo -e "${GREEN}Total RAM:${NC} $TOTAL_RAM_MB"

    MEM_USAGE=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
    echo -e "${GREEN}Memory Usage:${NC} ${MEM_USAGE}"
    
    SWAP_USAGE=$(free -m | awk 'NR==3{printf "%.2f%%", $3*100/$2 }')
    echo -e "${GREEN}Swap Usage:${NC} ${SWAP_USAGE}"
    
    DISK_USAGE=$(df -h | awk '$NF=="/"{printf "%s of total disk space used", $5}')
    echo -e "${GREEN}Disk Usage:${NC} ${DISK_USAGE}"
    
    LOAD_AVERAGE=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
    echo -e "${GREEN}Load Average (1, 5, 15 min):${NC} ${LOAD_AVERAGE}"
    
    ACTIVE_INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    LOCAL_IP=$(ip -4 addr show $ACTIVE_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    PUBLIC_IP=$(curl -s https://ipv4.icanhazip.com)
    echo -e "${GREEN}Local IPv4 Address:${NC} ${LOCAL_IP}"
    echo -e "${GREEN}Public IPv4 Address:${NC} ${PUBLIC_IP}"
    
    ACTIVE_CONNS=$(ss -tun | grep -vc "State")
    echo -e "${GREEN}Active Connections:${NC} ${ACTIVE_CONNS}"
    
    MYSQL_RUNNING=$(pgrep mysql > /dev/null && echo "Running" || echo "Not Running")
    NGINX_RUNNING=$(pgrep nginx > /dev/null && echo "Running" || echo "Not Running")
    REDIS_RUNNING=$(pgrep redis-server > /dev/null && echo "Running" || echo "Not Running")
    echo -e "${GREEN}MySQL Service:${NC} ${MYSQL_RUNNING}"
    echo -e "${GREEN}Nginx Service:${NC} ${NGINX_RUNNING}"
    echo -e "${GREEN}Redis Service:${NC} ${REDIS_RUNNING}"
    
    USER_SESSIONS=$(who | wc -l)
    echo -e "${GREEN}Active User Sessions:${NC} ${USER_SESSIONS}"
    
    UPTIME=$(uptime -p)
    echo -e "${GREEN}System Uptime:${NC} ${UPTIME}"
}

handle_invalid_choice() {
    echo "Invalid choice: $1. Please try again."
}

display_menu() {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    BOLD='\033[1m'
    UNDERLINE='\033[4m'

    clear
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${BLUE}${BOLD}    FiveM Server Management Script    ${NC}"
    echo -e "${YELLOW}========================================${NC}\n"

    # Server Management
    echo -e "${GREEN}${BOLD}Server Management:${NC}"
    echo -e "${GREEN}${BOLD}1.${NC} ${UNDERLINE}Create a new server${NC} - Setup a new server instance."
    echo -e "${GREEN}${BOLD}2.${NC} ${UNDERLINE}Start a server${NC} - Launch your chosen server."
    echo -e "${GREEN}${BOLD}3.${NC} ${UNDERLINE}Stop a server${NC} - Safely shutdown a server."
    echo -e "${GREEN}${BOLD}4.${NC} ${UNDERLINE}Monitor server console${NC} - View real-time console output."
    echo -e "${GREEN}${BOLD}5.${NC} ${UNDERLINE}Delete Server${NC} - Remove a server and its files.\n"

    # Server Utilities
    echo -e "${GREEN}${BOLD}Server Utilities:${NC}"
    echo -e "${GREEN}${BOLD}6.${NC} ${UNDERLINE}Update txAdmin${NC} - Upgrade txAdmin to the latest."
    echo -e "${GREEN}${BOLD}7.${NC} ${UNDERLINE}Debug a server${NC} - Troubleshoot server issues."
    echo -e "${GREEN}${BOLD}8.${NC} ${UNDERLINE}Update script${NC} - Get the latest script version.\n"

    # Advanced Features
    echo -e "${GREEN}${BOLD}Advanced Features:${NC}"
    echo -e "${GREEN}${BOLD}9.${NC} ${UNDERLINE}Server Performance Monitoring${NC} - View and alert on server metrics."
    echo -e "${GREEN}${BOLD}10.${NC} ${UNDERLINE}Automated Backups${NC} - Configure and manage server backups."
    echo -e "${GREEN}${BOLD}11.${NC} ${UNDERLINE}Mod Management${NC} - Install and update game mods."
    echo -e "${GREEN}${BOLD}12.${NC} ${UNDERLINE}Security Enhancements${NC} - Implement security measures and monitoring.\n"

    # Additional Tools
    echo -e "${GREEN}${BOLD}Additional Tools:${NC}"
    echo -e "${GREEN}${BOLD}13.${NC} ${UNDERLINE}API Integration${NC} - Utilize external APIs for extended functionality."
    echo -e "${GREEN}${BOLD}14.${NC} ${UNDERLINE}Plugin System${NC} - Extend script capabilities with plugins.\n"

    # General
    echo -e "${GREEN}${BOLD}General Options:${NC}"
    echo -e "${GREEN}${BOLD}0.${NC} ${UNDERLINE}Exit${NC} - Close the script.\n"

    echo -e "${YELLOW}========================================${NC}\n"
}

while true; do
    display_menu
    read -p "$(echo -e ${BLUE}Enter your choice:${NC} )" choice
    case $choice in
        1) create_server ;;
        2) start_server ;;
        3) stop_server ;;
        4) monitor_server ;;
        5) delete_server ;;
        6) update_txAdmin ;; 
        7) debug_server ;;
        8) update_script ;;
        # Placeholder for new advanced feature implementations
        9) monitor_server_performance ;;
        10) echo "Automated Backups feature coming soon..." ;;
        11) echo "Mod Management feature coming soon..." ;;
        12) echo "Security Enhancements feature coming soon..." ;;
        13) echo "API Integration feature coming soon..." ;;
        14) echo "Plugin System feature coming soon..." ;;
        0 | exit | stop | quit) echo -e "${RED}Exiting the script. Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
    esac
    read -p "$(echo -e ${YELLOW}Press enter to continue...${NC})"
done
