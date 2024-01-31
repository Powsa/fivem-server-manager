# FiveM Server Management Script

This shell script is designed to simplify the management of a FiveM server within a `screen` session on a Linux server. It provides various commands for controlling the server, checking its status, and attaching to its session.

## Prerequisites

Before using this script, ensure that the following prerequisites are met:

- **Linux Server**: The script is intended for use on a Linux server environment.
- **Directories**: You must have two directories, "alpine" and "resources," in the same directory as this script.
- **Configuration File**: A configuration file named "server.cfg" is required for the server to function correctly.

## Usage

To use the script, execute it with the following commands:

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