# FiveM Server Management Script

This tutorial covers the setup and use of a Bash script designed to manage a FiveM server. The script automates several tasks, including checking for necessary software, starting and stopping the server, and creating a new server with a default configuration.

## Prerequisites

Before running the script, ensure your system has the following software installed:

- Git
- xz-utils
- curl
- screen

The script includes checks for these dependencies and provides instructions for installing any that are missing.

## Installation

1. **Download the Script**: Clone this repository or download the script file directly to your local machine.
2. **Make the Script Executable**: Change the script's permissions to make it executable. Open a terminal and navigate to the directory containing the script. Run:

    ```bash
    chmod +x fivem_server_management.sh
    ```

3. **Run the Script**: Execute the script with:

    ```bash
    ./fivem_server_management.sh
    ```

## Usage

The script provides a menu with several options for managing your FiveM server:

1. **Create a New Server**: This option clones the necessary FiveM server data, downloads the latest FiveM server build, extracts it, removes unnecessary files, and creates a basic `server.cfg`.

2. **Start the Server**: Initiates the FiveM server using a screen session.

3. **Stop the Server**: Gracefully stops the FiveM server.

4. **Monitor the Server Console**: Attaches to the screen session hosting the FiveM server, allowing you to monitor its output.

6. **Exit**: Closes the script.

### Creating a New Server

When creating a new server, you'll be prompted to enter a server name. The script then performs the following actions:

- Creates a server directory.
- Clones the `cfx-server-data` repository into the directory.
- Downloads and extracts the latest FiveM build.
- Removes the downloaded archive and any `.gitignore` files.
- Creates and populates a default `server.cfg` file with basic server setup.

### Configuration

After creating a new server, you may want to customize the `server.cfg` file. This file is located in your server directory and can be edited to adjust server settings, resources, and other configurations.

## Troubleshooting

If you encounter issues while running the script, ensure that:

- All prerequisites are correctly installed.
- You have sufficient permissions to execute the script and access the directories and files it manipulates.
- Your internet connection is stable, as the script downloads data from the internet.

For detailed error messages, refer to the script's output. It provides specific instructions for resolving common issues.

## Contributing

Contributions to the script or documentation are welcome. Please feel free to fork the repository, make your changes, and submit a pull request.
