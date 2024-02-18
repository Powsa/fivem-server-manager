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
    local script_dir="$(dirname "$(realpath "$0")")"
    local available_servers=()
    for dir in "$script_dir"/*/; do
        if [ -f "${dir}run.sh" ]; then
            available_servers+=("$dir")
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo "No servers found in the server directory. Cannot stop any servers."
        return 1
    fi
    echo "Available servers:"
    for ((i=0; i<${#available_servers[@]}; i++)); do
        local server_name=$(basename "${available_servers[$i]}")
        echo "$((i+1)). $server_name"
    done
    read -p "Enter the number of the server to stop (0 to cancel): " choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#available_servers[@]} ]; then
        echo "Invalid choice. Operation cancelled."
        return 1
    fi
    if [ "$choice" -eq 0 ]; then
        echo "Operation cancelled by user."
        return 0
    fi
    local selected_server_path="${available_servers[$((choice-1))]}"
    local selected_server_name=$(basename "$selected_server_path")
    if screen -S "$selected_server_name" -X quit; then
        echo "Server $selected_server_name stopped successfully."
        local log_path="${selected_server_path}server.log"
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

perform_automated_backup() {
    echo -e "${YELLOW}Initiating automated backup...${NC}"
    local script_dir="$(dirname "$(realpath "$0")")"
    local backup_dir="${script_dir}/backup"
    mkdir -p "$backup_dir"
    echo "Available servers for backup:"
    local available_servers=()
    local i=0
    for dir in "$script_dir"/*/; do
        if [ -d "$dir" ] && [ -f "${dir}run.sh" ]; then
            local server_name=$(basename "$dir")
            available_servers+=("$server_name")
            ((i++))
            echo "$i. $server_name"
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo -e "${RED}No servers found to backup.${NC}"
        return
    fi
    read -p "Enter the number of the server you want to backup (or '0' to cancel): " server_choice
    if [[ "$server_choice" == "0" ]]; then
        echo "Backup operation cancelled."
        return
    fi
    if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#available_servers[@]} ]; then
        echo -e "${RED}Invalid selection. Please try again.${NC}"
        return
    fi
    local target="${available_servers[$server_choice-1]}"
    local target_dir="${script_dir}/${target}"
    local backup_filename="server_backup_${target}_$(date +%Y%m%d_%H%M%S)"
    read -p "Do you want to backup the database for ${target}? (y/n): " backup_db
    if [[ "$backup_db" =~ ^[Yy]$ ]]; then
        local server_cfg="${target_dir}/server.cfg"
        if [ -f "$server_cfg" ]; then
            local db_info=$(grep 'set mysql_connection_string' "$server_cfg" | cut -d '"' -f 2)
            local username=$(echo $db_info | cut -d ':' -f 2 | cut -d '/' -f 3)
            local password=$(echo $db_info | cut -d '@' -f 1 | cut -d ':' -f 3)
            local db=$(echo $db_info | cut -d '/' -f 4 | cut -d '?' -f 1)
            local host=$(echo $db_info | cut -d '@' -f 2 | cut -d '/' -f 1)
            local db_backup_filename="${backup_filename}_db.sql"
            echo "Performing database backup..."
            mysqldump -u "$username" -p"$password" -h "$host" "$db" > "${target_dir}/${db_backup_filename}"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Database backup of ${target} completed successfully: ${db_backup_filename}${NC}"
            else
                echo -e "${RED}Database backup failed for ${target}.${NC}"
                return 1
            fi
        else
            echo "Server configuration file not found. Skipping database backup."
        fi
    fi
    backup_filename="${backup_filename}.tar.gz"
    tar -czf "${backup_dir}/${backup_filename}" -C "$script_dir" "$target" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}File backup of ${target} completed successfully: ${backup_filename}${NC}"
    else
        echo -e "${RED}File backup failed for ${target}.${NC}"
        return 1
    fi
    [[ "$backup_db" =~ ^[Yy]$ ]] && rm -f "${target_dir}/${db_backup_filename}"
    local keep_last_n=5
    echo "Cleaning up old backups, keeping the last $keep_last_n backups..."
    find "$backup_dir" -type f -name 'server_backup_*' | sort -r | tail -n +$((keep_last_n + 1)) | xargs rm -f
}

handle_invalid_choice() {
    echo "Invalid choice: $1. Please try again."
}

manage_security() {
    echo -e "${YELLOW}Security Enhancements Menu:${NC}"
    echo "1. Configure Firewall"
    echo "2. Harden SSH"
    echo "3. Perform System Updates"
    echo "4. Setup Fail2Ban"
    echo "5. Perform Security Audit"
    read -p "Select an option: " security_action

    case $security_action in
        1) configure_firewall ;;
        2) harden_ssh ;;
        3) perform_updates ;;
        4) setup_fail2ban ;;
        5) perform_security_audit ;;
        *) echo -e "${RED}Invalid option selected. Please try again.${NC}" ;;
    esac
}

configure_firewall() {
    echo -e "${YELLOW}Initiating firewall configuration for enhanced security...${NC}"
    available_servers=()
    script_dir="$(dirname "$(realpath "$0")")"
    echo "Searching for servers in ${script_dir}..."
    for server_dir in "$script_dir"/*; do
        if [ -d "$server_dir" ] && [ -f "$server_dir/run.sh" ]; then
            server_name=$(basename "$server_dir")
            available_servers+=("$server_name")
        fi
    done
    if [ ${#available_servers[@]} -eq 0 ]; then
        echo -e "${RED}No servers found. Please ensure server directories are present and contain a run.sh script.${NC}"
        return 1
    fi
    echo "Available servers for firewall configuration:"
    for i in "${!available_servers[@]}"; do
        echo "$((i+1)). ${available_servers[$i]}"
    done
    read -p "Select the server to configure firewall for (enter number): " server_choice
    let server_choice-=1
    if [[ $server_choice -lt 0 || $server_choice -ge ${#available_servers[@]} ]]; then
        echo -e "${RED}Invalid selection.${NC}"
        return 1
    fi
    server_cfg="${script_dir}/${available_servers[$server_choice]}/server.cfg"
    if [ -f "$server_cfg" ]; then
        tcp_port=$(grep "endpoint_add_tcp" "$server_cfg" | cut -d '"' -f 2 | cut -d ':' -f 2)
        udp_port=$(grep "endpoint_add_udp" "$server_cfg" | cut -d '"' -f 2 | cut -d ':' -f 2)
        if [[ -z $tcp_port || -z $udp_port ]]; then
            echo -e "${RED}Could not extract TCP or UDP port from server.cfg.${NC}"
            return 1
        fi
        echo "Configuring UFW with essential ports and those extracted from the server configuration..."
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow $tcp_port/tcp
        sudo ufw allow $udp_port/udp
        read -p "Do you want to allow external access to txAdmin on port 40120? (y/n): " allow_txadmin
        if [[ $allow_txadmin =~ ^[Yy]$ ]]; then
            sudo ufw allow 40120/tcp
            echo -e "${GREEN}txAdmin port 40120 opened successfully.${NC}"
        fi
        if sudo ufw status | grep -q "inactive"; then
            sudo ufw --force enable
            echo -e "${GREEN}Firewall enabled and configured successfully for ${available_servers[$server_choice]}.${NC}"
        else
            sudo ufw reload
            echo -e "${GREEN}Firewall rules reloaded and applied successfully for ${available_servers[$server_choice]}.${NC}"
        fi
        echo -e "${GREEN}Firewall rules configured successfully for ${available_servers[$server_choice]}.${NC}"
    else
        echo -e "${RED}server.cfg not found for selected server.${NC}"
        return 1
    fi
}

harden_ssh() {
    echo -e "${YELLOW}Hardening SSH configuration...${NC}"
    user_home=$(eval echo ~$(whoami))
    if [ -f "${user_home}/.ssh/authorized_keys" ]; then
        echo -e "${GREEN}SSH keys setup detected for $(whoami). Proceeding with disabling password authentication.${NC}"
        ssh_config_file="/etc/ssh/sshd_config"
        sudo cp $ssh_config_file "${ssh_config_file}.bak"
        sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' $ssh_config_file
        read -p "Disable password authentication? This requires SSH keys for login (y/n): " disable_pass_auth
        if [[ $disable_pass_auth == [Yy] ]]; then
            sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' $ssh_config_file
            sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' $ssh_config_file
            echo -e "${GREEN}Password authentication disabled.${NC}"
        else
            echo -e "${YELLOW}Keeping password authentication enabled.${NC}"
        fi
        sudo systemctl reload sshd
    else
        echo -e "${RED}No SSH keys setup detected for $(whoami). Please configure SSH keys before disabling password authentication.${NC}"
    fi
}

perform_updates() {
    echo -e "${YELLOW}Updating server software...${NC}"
    if sudo apt-get update; then
        echo -e "${GREEN}Package lists updated successfully.${NC}"
    else
        echo -e "${RED}Failed to update package lists. Check your network connection and repository configuration.${NC}"
        return 1
    fi
    if sudo apt-get upgrade -y; then
        echo -e "${GREEN}Packages upgraded successfully.${NC}"
    else
        echo -e "${RED}Failed to upgrade packages.${NC}"
        return 1
    fi
    read -p "Do you want to remove obsolete packages and clean up? (y/n): " cleanup_choice
    if [[ $cleanup_choice == [Yy] ]]; then
        sudo apt-get autoremove -y && sudo apt-get autoclean -y
        echo -e "${GREEN}System cleaned up successfully.${NC}"
    fi
    if [ -f /var/run/reboot-required ]; then
        echo -e "${YELLOW}A reboot is required to complete the update process.${NC}"
        read -p "Do you want to reboot now? (y/n): " reboot_choice
        if [[ $reboot_choice == [Yy] ]]; then
            echo -e "${YELLOW}Rebooting now...${NC}"
            sudo reboot
        else
            echo -e "${YELLOW}Remember to reboot the system later to apply all updates.${NC}"
        fi
    else
        echo -e "${GREEN}System updated successfully. No reboot required.${NC}"
    fi
}

setup_fail2ban() {
    echo -e "${YELLOW}Checking for Fail2Ban installation...${NC}"
    if command -v fail2ban-client &> /dev/null; then
        echo -e "${GREEN}Fail2Ban is already installed.${NC}"
    else
        echo -e "${YELLOW}Installing Fail2Ban...${NC}"
        if sudo apt-get install fail2ban -y; then
            echo -e "${GREEN}Fail2Ban installed successfully.${NC}"
        else
            echo -e "${RED}Failed to install Fail2Ban. Please check your package manager and internet connection.${NC}"
            return 1
        fi
    fi
    echo -e "${YELLOW}Enabling and starting Fail2Ban...${NC}"
    if sudo systemctl enable fail2ban && sudo systemctl start fail2ban; then
        echo -e "${GREEN}Fail2Ban enabled and started successfully.${NC}"
    else
        echo -e "${RED}Failed to enable or start Fail2Ban. Please check the system logs for more details.${NC}"
        return 1
    fi
    echo -e "${YELLOW}Verifying Fail2Ban status...${NC}"
    if sudo systemctl is-active --quiet fail2ban; then
        echo -e "${GREEN}Fail2Ban is running.${NC}"
    else
        echo -e "${RED}Fail2Ban is not running. Please investigate the issue with 'sudo systemctl status fail2ban'.${NC}"
        return 1
    fi
    read -p "Do you want to apply a custom Fail2Ban configuration? (y/N): " apply_custom_config
    if [[ "$apply_custom_config" =~ ^[Yy]$ ]]; then
        read -p "Enter the full path to your custom Fail2Ban configuration file: " custom_config_path
        if [ -f "$custom_config_path" ]; then
            custom_config_dir="/etc/fail2ban"
            sudo cp "$custom_config_path" "$custom_config_dir"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Custom Fail2Ban configuration applied successfully.${NC}"
                sudo systemctl reload fail2ban
            else
                echo -e "${RED}Failed to apply custom Fail2Ban configuration. Please check the file path and permissions.${NC}"
                return 1
            fi
        else
            echo -e "${RED}Configuration file does not exist at the specified path. Skipping custom configuration.${NC}"
        fi
    fi
}

perform_security_audit() {
    echo -e "${YELLOW}Checking for Lynis installation...${NC}"
    if command -v lynis &> /dev/null; then
        echo -e "${GREEN}Lynis is already installed.${NC}"
    else
        echo -e "${YELLOW}Installing Lynis...${NC}"
        if sudo apt-get install lynis -y; then
            echo -e "${GREEN}Lynis installed successfully.${NC}"
        else
            echo -e "${RED}Failed to install Lynis. Please check your package manager and internet connection.${NC}"
            return 1
        fi
    fi
    echo -e "${YELLOW}Performing security audit with Lynis...${NC}"
    read -p "Do you want to perform a full system audit or a custom audit? (F/c): " audit_choice
    case $audit_choice in
        [cC]* )
            read -p "Enter Lynis audit options (e.g., --tests-from group, --check-update): " custom_options
            audit_command="sudo lynis $custom_options"
            ;;
        * )
            audit_command="sudo lynis audit system"
            ;;
    esac
    if $audit_command; then
        echo -e "${GREEN}Lynis audit completed successfully.${NC}"
    else
        echo -e "${RED}Lynis audit encountered an issue. Please check the output above for details.${NC}"
        return 1
    fi
    read -p "Do you want to save the audit report to a file? (y/N): " save_report
    if [[ "$save_report" =~ ^[Yy]$ ]]; then
        report_file="/var/log/lynis-$(date +%Y%m%d-%H%M%S).log"
        if $audit_command > "$report_file" 2>&1; then
            echo -e "${GREEN}Lynis audit report saved to ${report_file}.${NC}"
        else
            echo -e "${RED}Failed to save Lynis audit report. Please check permissions and disk space.${NC}"
            return 1
        fi
    fi
}

display_menu() {
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    BOLD='\033[1m'
    UNDERLINE='\033[4m'

    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    LIGHT_GREEN='\033[1;32m'
    LIGHT_CYAN='\033[1;36m'
    LIGHT_RED='\033[1;31m'
    LIGHT_YELLOW='\033[1;33m'
    LIGHT_MAGENTA='\033[1;35m'

    clear
    printf "${LIGHT_YELLOW}========================================${NC}\n"
    printf "${LIGHT_CYAN}${BOLD}    FiveM Server Management Script    ${NC}\n"
    printf "${LIGHT_YELLOW}========================================${NC}\n\n"

    printf "${LIGHT_GREEN}Server Management:${NC}\n"

    printf "${CYAN}1. ${NC} %-30s${NC} - %s\n" "Create a new server" "Setup a new server instance."
    printf "${CYAN}2. ${NC} %-30s${NC} - %s\n" "Start a server" "Launch your chosen server."
    printf "${CYAN}3. ${NC} %-30s${NC} - %s\n" "Stop a server" "Safely shutdown a server."
    printf "${CYAN}4. ${NC} %-30s${NC} - %s\n" "Monitor server console" "View real-time console output."
    printf "${CYAN}5. ${NC} %-30s${NC} - %s\n" "Backup server" "Configure and manage server backups."
    printf "${CYAN}6. ${NC} %-30s${NC} - %s\n" "Debug a server" "Troubleshoot server issues."
    printf "${CYAN}7. ${NC} %-30s${NC} - %s\n\n" "Delete Server" "Remove a server and its files."

    printf "${LIGHT_GREEN}Server Utilities:${NC}\n"
    printf "${CYAN}8. ${NC} %-30s${NC} - %s\n" "Update txAdmin" "Upgrade txAdmin to the latest."
    printf "${CYAN}9. ${NC} %-30s${NC} - %s\n" "Update script" "Get the latest script version."
    printf "${CYAN}10.${NC} %-30s${NC} - %s\n" "Server Performance Monitoring" "View and alert on server metrics."
    printf "${CYAN}11.${NC} %-30s${NC} - %s\n\n" "Security Enhancements" "Implement security measures and monitoring."

    printf "${LIGHT_GREEN}General Options:${NC}\n"
    printf "${CYAN}0. ${NC} %-30s${NC} - %s\n\n" "Exit" "Close the script."

    printf "${LIGHT_YELLOW}========================================${NC}\n\n"
}

while true; do
    display_menu
    read -p "$(echo -e Enter your choice:${NC} )" choice
    case $choice in
        1) create_server ;;
        2) start_server ;;
        3) stop_server ;;
        4) monitor_server ;;
        5) perform_automated_backup ;;
        6) debug_server ;;
        7) delete_server ;;
        8) update_txAdmin ;; 
        9) update_script ;;
        10) monitor_server_performance ;;
        11) manage_security ;;
        0 | exit | stop | quit) echo -e "${RED}Exiting the script. Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
    esac
    read -p "$(echo -e ${YELLOW}Press enter to continue...${NC})"
done
