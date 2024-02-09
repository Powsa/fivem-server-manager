# FiveM Server Manager

FiveM Server Manager is a Bash script designed to simplify the management of FiveM servers. Whether you're setting up a new server, starting an existing one, or troubleshooting issues, this script provides a convenient interface to perform common tasks efficiently.

## Features

- **Dependency Installation**: The script automatically checks for and installs required dependencies (`git`, `xz`, `curl`) if they are not already installed on your system.
  
- **Server Management**: Easily create, start, stop, monitor, debug, and update FiveM servers with intuitive commands. The script streamlines these tasks, reducing manual effort and potential errors.
  
- **Interactive Menu System**: The script presents a user-friendly menu that guides you through various server management options. This interface is particularly helpful for users who are not familiar with command-line operations.
  
- **Error Handling**: If any errors occur during dependency installation or server management tasks, the script provides informative messages and options for retrying, skipping, or exiting gracefully.
  
- **Script Management**: Keep your script up to date by easily updating it from the GitHub repository. This ensures you have access to the latest features, bug fixes, and improvements.

## Usage

1. **Clone the Repository**: Start by cloning this repository to your local machine using the following command:
   ```bash
   git clone https://github.com/Syslogine/fivem-server-manager.git
   ```

2. **Navigate to the Directory**: Move into the cloned directory:
   ```bash
   cd fivem-server-manager
   ```

3. **Make the Script Executable**: Ensure that the script has the necessary permissions to be executed:
   ```bash
   chmod +x fivemanager.sh
   ```

4. **Run the Script**: Execute the script to access the interactive menu:
   ```bash
   ./fivemanager.sh
   ```

5. **Follow the Menu Options**: Use the numbered menu options to perform various server management tasks such as creating a new server, starting or stopping an existing server, monitoring server output, debugging, or updating the script itself.

## Contributing

Contributions are welcome! If you encounter any issues, have suggestions for improvements, or want to contribute code enhancements, feel free to open an issue or submit a pull request. Your input helps make this project better for everyone.

## License

This project is licensed under the [MIT License](LICENSE), which means you are free to use, modify, and distribute the script for both personal and commercial purposes, with appropriate attribution.

## Credits

This script is maintained by [Yarpii](https://github.com/Syslogine), aiming to simplify the management of FiveM servers for users of all experience levels.