#!/bin/bash

# IMPORTANT: This script is designed to work on Windows 11, Linux, and macOS.
# If you are using Windows 10 or lower, the script may not work as expected.
# Please ensure you are running it in an environment that meets the requirements.

declare -g SERVER_NAME
declare -g DEPENDENCIES
declare -g SERVER_BUILD_URL
declare -g LICENSE_KEY

# Function to log messages with a timestamp
log_message() {
    local log_file="${server_directory}/server.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Function to check for required dependencies and offer to install them (Linux, Windows, and macOS)
check_dependencies() {
    local missing_deps=()
    local os_name=$(uname -s)

    # Include 'jq' for JSON parsing along with other dependencies
    for dep in git xz jq; do
        if ! command -v "$dep" &> /dev/null; then
            # For Windows, check only git and jq as xz might not be directly applicable
            if [ "$os_name" = "Linux" ] || ([ "$os_name" = "Windows" ] && [[ "$dep" = "git" || "$dep" = "jq" ]]); then
                missing_deps+=("$dep")
            elif [ "$os_name" = "Darwin" ]; then
                # Assuming macOS can handle all dependencies similarly to Linux
                missing_deps+=("$dep")
            fi
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "The following packages are required but not installed: ${missing_deps[*]}"
        read -p "Would you like to install them now? (y/n): " answer
        if [[ "$answer" = "y" ]]; then
            case "$os_name" in
                "Linux")
                    sudo apt-get update && sudo apt-get install -y "${missing_deps[@]}"
                    ;;
                "Darwin")
                    if ! command -v brew &> /dev/null; then
                        echo "Installing Homebrew..."
                        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    fi
                    echo "Installing missing dependencies with Homebrew..."
                    brew install "${missing_deps[@]}"
                    ;;
                "Windows")
                    for dep in "${missing_deps[@]}"; do
                        if [ "$dep" = "git" ] || [ "$dep" = "jq" ]; then
                            echo "$dep is required but not installed."
                            read -p "Would you like to open the download page for $dep now? (y/n): " open_page
                            if [[ "$open_page" = "y" ]]; then
                                if [ "$dep" = "git" ]; then
                                    powershell.exe -Command "Start-Process 'https://git-scm.com/download/win'"
                                elif [ "$dep" = "jq" ]; then
                                    powershell.exe -Command "Start-Process 'https://stedolan.github.io/jq/download/'"
                                fi
                                echo "Please install $dep following the instructions on the opened web page. After installation, rerun this script."
                            else
                                echo "Manual installation required: Please install $dep from the provided URL and then rerun this script."
                            fi
                        else
                            echo "Dependency '$dep' is not automatically installable on Windows. For manual installation, please search for installation instructions specific to $dep."
                        fi
                    done
                    ;;
                *)
                    echo "Dependency installation is not supported on this platform. Please ensure all dependencies are installed."
                    ;;
            esac
            echo "Dependencies installed or installation instructions provided."
        else
            exit 1
        fi
    fi
}

# Function to read JSON configuration with awk and sed
read_config() {
    local config_file="${1:-server_config.json}" # Use provided config file or default to 'server_config.json'

    # Check if the configuration file exists
    if [ ! -f "$config_file" ]; then
        echo "Configuration file ($config_file) not found."
        return 1
    else
        echo "Configuration file ($config_file) found. Reading configurations..."
    fi

    # Use awk to extract simple string values by key
    SERVER_NAME=$(awk -F'"' '/"server_name":/ {print $4}' "$config_file")
    SERVER_BUILD_URL=$(awk -F'"' '/"server_build_url":/ {print $4}' "$config_file")
    LICENSE_KEY=$(awk -F'"' '/"license_key":/ {print $4}' "$config_file")

    # Extract dependencies into a Bash array using sed and grep
    DEPENDENCIES=($(sed -n '/"dependencies": \[/,/\]/p' "$config_file" | grep -oP '"\K[^"]+'))

    # Validate required configurations to ensure they are not empty
    if [[ -z "$SERVER_NAME" || -z "$SERVER_BUILD_URL" || -z "$LICENSE_KEY" || ${#DEPENDENCIES[@]} -eq 0 ]]; then
        echo "One or more required configurations are missing in the configuration file."
        return 1
    fi

    # Confirmation of successful configuration reading
    echo "Configuration successfully loaded for server: $SERVER_NAME"
}


# Function to create the server directory and setup the server based on a JSON configuration
create_server() {
    # Check if the server_config.json file exists
    if [ ! -f "server_config.json" ]; then
        echo "Configuration file (server_config.json) not found."
        return 1
    fi

    # Reading configurations from the JSON file
    read_config
    if [ $? -ne 0 ]; then
        echo "Failed to read server configuration."
        exit 1
    fi

    local script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    local server_directory="$script_dir/$SERVER_NAME"
    
    # Check if the server directory already exists
    if [ -d "$server_directory" ]; then
        echo "A server with the name '$SERVER_NAME' already exists."
        read -p "Do you want to delete the old server and create a new one? (y/n): " delete_old
        
        if [[ "$delete_old" = "y" ]]; then
            echo "Deleting old server directory..."
            rm -rf "$server_directory"
            echo "Old server directory deleted."
            # Proceed to create a new server after deletion
        else
            echo "Operation cancelled. Please choose a different server name or modify the configuration."
            return 1 # Exit the function without creating a new server
        fi
    fi

    # Prompt user to confirm before proceeding with each step
    echo "Creating server directory at $server_directory..."
    mkdir -p "$server_directory" || {
        echo "Failed to create server directory."
        exit 1
    }
    echo "Server directory created."

    cd "$server_directory" || {
        echo "Failed to change to server directory."
        exit 1
    }

    if [ "$(uname -s)" = "Linux" ]; then
        echo "Attempting to download the server build from $SERVER_BUILD_URL..."

        # Download the server build and capture wget's exit status
        wget -q "$SERVER_BUILD_URL" -O fx.tar.xz
        wget_status=$?

        if [ $wget_status -ne 0 ]; then
            case $wget_status in
                1) echo "Generic error code. (Wget Exit Status: $wget_status)";;
                2) echo "Parse error—for instance, when parsing command-line options, the .wgetrc or .netrc...";;
                3) echo "File I/O error.";;
                4) echo "Network failure.";;
                5) echo "SSL verification failure.";;
                6) echo "Username/password authentication failure.";;
                7) echo "Protocol errors.";;
                8) echo "Server issued an error response.";;
                *) echo "Unknown error occurred. (Wget Exit Status: $wget_status)";;
            esac
            echo "Failed to download the server build from $SERVER_BUILD_URL. Please verify the URL and try again."
            echo "visit: https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
            exit 1
        fi

        echo "Download successful. Extracting the server build..."

        # Extract the server build
        if ! tar -xf fx.tar.xz; then
            echo "Failed to extract the server build."
            # Attempt to remove the partially extracted files if extraction fails
            echo "Cleaning up partially extracted files..."
            rm -rf alpine/ # or whatever directory the tar might extract to
            rm -f fx.tar.xz
            exit 1
        fi

        echo "Extraction successful. Cleaning up the archive..."

        # Remove the archive
        if ! rm -f fx.tar.xz; then
            echo "Failed to remove the server build archive. Manual cleanup may be required."
            # Not exiting with error here because the main tasks (download and extract) were successful
        fi

        echo "Server build downloaded, extracted, and archive removed successfully."

    elif [ "$(uname -s)" = "Darwin" ]; then
        # Hypothetical macOS-specific download logic
        curl -L "$SERVER_BUILD_URL" -o fx.tar.xz && tar -xf fx.tar.xz && rm -f fx.tar.xz || {
            echo "Failed to download, extract, or clean up the server build."
            exit 1
        }
        echo "Server build downloaded, extracted, and archive removed."
    else
        echo -n "Checking server build availability at the URL... "

        # Simulate waiting indicator for the URL check
        # Note: Actual wait indicator functionality during the PowerShell command execution is limited
        # due to synchronous execution nature. This is a placeholder for visual feedback.
        echo -n "[Checking]"
        sleep 1  # Simulating delay for demonstration; remove or adjust according to actual task duration
        echo ""

        # Use PowerShell to check if the server build is available
        check_result=$(powershell -Command "& {
            try {
                \$response = Invoke-WebRequest -Uri '${SERVER_BUILD_URL}' -Method Head -ErrorAction Stop
                if (\$response.StatusCode -ne 200) {
                    Write-Output 'not_found'
                } else {
                    Write-Output 'found'
                }
            } catch {
                Write-Output 'error: ' + \$_
            }
        }")

        if [[ "$check_result" == "not_found" ]]; then
            echo "Server build not found at the specified URL. Please check the URL."
            echo "For the latest server build, visit: https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
            read -p "Press Enter to exit and correct the URL..."
            exit 1
        elif [[ "$check_result" =~ "error:" ]]; then
            echo "Error checking server build availability: ${check_result}"
            read -p "Press Enter to exit..."
            exit 1
        else
            echo "Server build found. Attempting to download... [Found]"
        fi

        echo -n "Downloading server build... "
        # Add a simple visual feedback for download attempt
        echo -n "[Downloading]"
        sleep 1  # Simulating delay for demonstration
        echo ""

        # Proceed with download only if the check above is successful
        download_result=$(powershell -Command "& {
            try {
                Invoke-WebRequest -Uri '${SERVER_BUILD_URL}' -OutFile 'fx.tar.xz' -ErrorAction Stop
                Write-Output 'success'
            } catch {
                Write-Output 'failed: ' + \$_
            }
        }")

        if [[ "$download_result" != "success" ]]; then
            echo "Failed to download the server build. Please check the URL and try again."
            exit 1
        fi

        # Extraction process
        echo -n "Extracting the server build... "
        if ! wsl tar -xf fx.tar.xz; then
            echo -e "\r\033[KFailed to extract the server build. Check if WSL is installed and configured correctly."
            rm -f fx.tar.xz  # Cleanup attempt
            exit 1
        else
            echo -e "\r\033[KExtraction: Successful."
        fi

        # Cleanup process
        echo -n "Cleaning up the archive... "
        if ! rm -f fx.tar.xz; then
            echo -e "\r\033[KFailed to remove the server build archive. Manual cleanup may be required."
        else
            echo -e "\r\033[KCleanup: Successful."
        fi
    fi

    local resources_directory="$server_directory/resources"
    echo "Creating resources directory..."
    mkdir -p "$resources_directory" || {
        echo "Failed to create the resources directory."
        exit 1
    }
    echo "Resources directory created."

    local server_cfg_file="$server_directory/server.cfg"
    echo "Creating server.cfg file with predefined license key..."
    cat <<EOL > "$server_cfg_file"
# Your server configuration file.
# Customize as needed.
sv_licenseKey "$LICENSE_KEY"
EOL
    echo "server.cfg file created."

    echo "Setup completed!"
    echo ""
    echo "Configure your server further in $server_cfg_file"
    echo "To start your server, run this script again with the 'start' option: $(basename "${BASH_SOURCE[0]}") start"

    echo ""
    read -p "Server is now installed and ready for copying files to it"
}

# Function to manage the screen session (Linux only)
manage_screen() {
    # Use the global SERVER_NAME variable set by read_config
    local screen_name="$SERVER_NAME" # Adjusted to use SERVER_NAME
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
        "attach")
            if screen -list | grep -q "\.$screen_name"; then
                screen -r "$screen_name"
            else
                echo "Screen session '$screen_name' is not running."
                log_message "Attempted to attach to screen session '$screen_name', but it is not running."
            fi
            ;;
        *)
            echo "Invalid command: $1"
            log_message "Invalid command: $1"
            exit 1
            ;;
    esac
}

# Function to detect the operating system and check Windows version if applicable
detect_os() {
    local os=""
    if [ "$(uname -s)" = "Linux" ]; then
        os="Linux"
    elif [ "$(uname -s)" = "Darwin" ]; then
        os="macOS"
    else
        os="Windows"
        # Attempt to check Windows version via PowerShell command executed from WSL
        win_ver=$(powershell.exe -Command "[Environment]::OSVersion.Version | Format-List -Property *")
        
        # Assuming Windows 10 version format is 10.0.<Build Number>
        # We look for a build number to determine if it's Windows 10 or lower
        if echo "$win_ver" | grep -q 'Major 10'; then
            echo "Detected potentially unsupported Windows version: Windows 10 or lower."
            echo "This script is optimized for Windows 11, Linux, and macOS."
            # You can set a flag here or directly warn the user as needed
        else
            echo "Detected Windows version is Windows 11 or newer."
        fi
    fi
    echo "$os"
}

# Function to display an interactive menu
show_menu() {
    local os=$(detect_os)

    # Show an initial warning if the script is executed in a potentially unsupported environment
    if [ "$os" = "Windows" ]; then
        echo "Warning: This script is optimized for Windows 11, Linux, and macOS."
        echo "If you are using Windows 10 or lower, please proceed with caution as the script may not work as expected."
        # Wait for the user to acknowledge the warning
        read -p "Press any key to continue..." -n 1 -r
        echo
    fi
    
    while true; do
        clear
        echo "FiveM Server Management ($os)"
        echo "1. Create Server"
        echo "2. Start Server"
        echo "3. Stop Server"
        echo "4. Restart Server"
        echo "5. Server Status"
        echo "6. Attach to Server Session"
        echo "7. Exit"
        echo ""
        read -p "Enter choice [1-7 or 'exit']: " choice

        case $choice in
            1) create_server ;;
            2) manage_screen start ;;
            3) manage_screen stop ;;
            4) manage_screen restart ;;
            5) manage_screen status ;;
            6) manage_screen attach ;;
            7 | exit) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please enter a number between 1 and 7 or type 'exit'."; read -n 1 ;;
        esac
    done
}

# Start the script with the menu
show_menu
