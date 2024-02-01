# FiveM Server Management Script

This shell script facilitates the management and operation of a FiveM server within a Linux environment. It automates tasks such as server creation, starting, stopping, and monitoring within a `screen` session.

## Prerequisites

Before using this script, ensure the following conditions are met:

- **Linux Environment**: The script is intended for use on Linux servers.
- **Git and xz-utils**: These packages must be installed for the script to function correctly.
- **Server Directory**: The script will create a new directory for the server based on your input.
- **Configuration File**: The script generates a basic `server.cfg` file, which you can customize as needed.

## Installation

To install and use the script, you'll need to follow these steps:

1. **Obtain the Script**:

   You have two main options for obtaining the script:

   - **Direct Download**: If the script is hosted online (such as on a GitHub repository or a website), you can download it directly. Here's how:
     - Go to the source URL where the script is hosted.
     - Look for a download option or link. On GitHub, this might be a "Download" button or a command to clone the repository.
     - If it's a GitHub repository, you can clone it with:
       ```bash
       git clone https://github.com/Syslogine/fivem-server-manager.git
       ```
     - Save the script file to a directory of your choice on your Linux server.

   - **Manual Creation**: If direct download is not an option, or if you prefer creating the file manually, follow these steps:
     - Open a text editor on your Linux server.
     - Create a new file with a `.sh` extension (for example, `fivem_manager.sh`).
     - Copy and paste the content of the provided script into this new file.
     - Save the file in a directory where you wish to run the server management script.

2. **Make the Script Executable**:
   
   Once you have the script on your server, you need to make it executable. This allows the Linux system to run the script as a program. Here's how to do it:

   - Open your terminal.
   - Navigate to the directory where you saved the script. For example, if you saved it in `/home/user/scripts`, use the command:
     ```bash
     cd /home/user/scripts
     ```
   - Change the permissions of the script file to make it executable. Replace `fivemanager.sh` with the actual name of your script file:
     ```bash
     chmod +x fivemanager.sh
     ```
   - This command sets the execute permission for the user who owns the file, enabling you to run the script.

After completing these steps, the script will be ready to use. You can run it from the terminal in the directory where it's located using commands like `./fivemanager.sh create`, `./fivemanager.sh start`, and so on, as described in the Usage section of the documentation.

## Usage

Once the script is executable, you can use it to manage your FiveM server. Here's a breakdown of each command and its function:

### Create the Server

```bash
./fivemanager.sh create
```

- **What it does**:
  - **Prompts for Server Name**: You will be asked to enter a name for your server. This name is used to create a dedicated directory for your server.
  - **Prompts for Server Build URL**: You need to provide the URL of the FiveM server build you wish to use. This is where your server will download the necessary files from.
  - **Checks Dependencies**: The script checks if required dependencies (like Git and xz-utils) are installed. If not, it will alert you.
  - **Creates Directories and Configuration Files**: It sets up the server's directory structure, including a resources folder and a basic `server.cfg` file for initial configuration.

- **When to use it**: Run this command when you first set up your FiveM server or when you want to set up a new server instance.

### Start the Server

```bash
./fivemanager.sh start
```

- **What it does**:
  - **Starts the Server in a Screen Session**: If the server isn't already running, the script will start it in a detached `screen` session. This allows the server to run in the background.
  - **Handles Multiple Sessions**: If a session with the server's name already exists, it prevents starting another instance, ensuring that you don't accidentally run multiple servers.

- **When to use it**: Use this command to start the server after creating it or whenever you need to restart the server after stopping it.

### Stop the Server

```bash
./fivemanager.sh stop
```

- **What it does**:
  - **Stops the Server Gracefully**: This command stops the running screen session that contains your server, effectively stopping the server without abrupt termination.
  
- **When to use it**: Run this command to stop the server for maintenance, updates, or when it's no longer in use.

### Check Server Status

```bash
./fivemanager.sh status
```

- **What it does**:
  - **Displays the Server's Status**: The script checks whether the server's screen session is active and informs you if the server is running or not.

- **When to use it**: This command is useful for quickly checking if your server is up and running, especially useful in troubleshooting scenarios.

### Attach to Server Session

```bash
./fivemanager.sh attach
```

- **What it does**:
  - **Attaches to the Active Server Session**: This allows you to interact directly with the server's console. It's useful for server administration tasks that require direct console access.
  - **Detaching**: To detach and leave the server running in the background, press `Ctrl+A` followed by `D`.

- **When to use it**: Use this command when you need to perform manual operations or checks on the server through the console.

### Invalid Command or Help

```bash
./fivemanager.sh
```

- **What it does**:
  - **Displays Usage Instructions**: If you provide an invalid command or no arguments, the script will display a help message outlining the valid commands and their basic usage.

- **When to use it**: Run this command if you are unsure of the available commands or need a reminder of how to use the script.

## Error Handling

The script includes checks for required dependencies and displays error messages if necessary. It ensures that all prerequisites are met before proceeding with server operations.

## Contributions

Your contributions to improve or enhance this script are welcome. Feel free to modify, fork, or suggest improvements through pull requests.
