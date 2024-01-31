
# FiveM Server Management Script

This shell script simplifies the management of a FiveM server within a `screen` session on a Linux server. It provides various commands for controlling the server, checking its status, and attaching to its session.

## Prerequisites

Before using this script, please ensure that the following prerequisites are met:

- **Linux Server**: The script is designed for Linux server environments.
- **Directories**: You must have two directories, "alpine" and "resources," in the same directory as this script.
- **Configuration File**: A configuration file named "server.cfg" is required for the server to function correctly.

## Installation

To use this script, follow these steps:

1. **Download the Script from GitHub**:

   To get the script, you need to access the GitHub repository where it is hosted. Here's how you can do it:

   - **Option 1: Clone the Repository (Recommended)**:
   
     Cloning the repository allows you to have a local copy of the entire project, which is useful if you plan to work with or contribute to the script in the future. Follow these steps:

     - Open your terminal or command prompt.
     - Navigate to the directory where you want to store the script and other repository files.
     - Run the following command to clone the repository:
       ```bash
       git clone https://github.com/Syslogine/fivem-screen-manager.git
       ```
     - Once the clone operation is complete, you will have a local copy of the script and the entire repository.

   - **Option 2: Download the Script File Directly**:

     If you only need the script itself and do not intend to work with the entire repository, you can download the script file directly from GitHub. Follow these steps:

     - Visit the [GitHub repository page](https://github.com/Syslogine/fivem-screen-manager) in your web browser.
     - Click on the "Code" button, which is usually located near the top right corner of the repository page.
     - In the dropdown menu, select "Download ZIP." This will download a compressed ZIP archive containing the script and all associated files.
     - Once the download is complete, you can extract the script file from the ZIP archive to the directory where you want to use it.

   Regardless of the option you choose, you will have the script available locally for execution on your Linux server.

2. **Make the Script Executable**: After downloading, navigate to the script's directory and make it executable using the following command:

    ```bash
    chmod +x start_fivem_server.sh
    ```

## Usage

Once you have downloaded and made the script executable, you can use it with the following commands:

### Start the Server

```bash
./start_fivem_server.sh start
```

- Checks if the screen session is already running and starts the server if it's not.
- Creates a detached `screen` session with the specified command from "run.sh."

### Stop the Server

```bash
./start_fivem_server.sh stop
```

- Checks if the screen session is running and stops it gracefully.

### Check Server Status

```bash
./start_fivem_server.sh status
```

- Checks and displays the status of the screen session.

### Attach to Server Session

```bash
./start_fivem_server.sh attach
```

- Attaches to the screen session if it's running, allowing you to interact with the server.
- Detach from the session using `Ctrl+A` followed by `D`.

### Additional Commands

If you provide an invalid command or require usage information, the script will display the usage instructions.

```bash
Usage: ./start_fivem_server.sh {start|stop|status|attach}
```

## Error Handling

The script checks for the existence of required directories and configuration files and provides error messages when necessary. If any of the prerequisites are missing, it will prevent the script from running.

## Contributions

Contributions and enhancements to this script are welcome. Feel free to fork the repository, make improvements, and submit pull requests.

## License

This project is open-source and available under the MIT License.