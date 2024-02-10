# FiveM Server Manager

Welcome to the advanced FiveM Server Manager! This script is a powerful tool designed to simplify the management and administration of FiveM servers, offering a wide range of features to meet the needs of server owners and administrators. Below is an in-depth overview of the script's advanced functionality:

## Usage

To make the most of the advanced features provided by the script, follow these steps:

1. **Clone the Repository**: Begin by cloning this repository to your local machine. Open your terminal or command prompt and execute the following command:
   ```bash
   git clone https://github.com/Syslogine/fivem-server-manager.git
   ```

2. **Navigate to the Script Directory**: Move into the directory containing the script using the `cd` command followed by the directory name:
   ```bash
   cd fivem-server-manager
   ```

3. **Execute the Script**: Once inside the script directory, execute the script by running the following command in your terminal:
   ```bash
   ./fivemanager.sh
   ```

4. **Follow On-screen Prompts**: The script will present you with a menu displaying various advanced options for managing your server. Simply follow the on-screen prompts to perform your desired actions.

## Requirements

To use this script effectively, ensure that your system meets the following requirements:

- Linux Operating System (Ubuntu, Debian, etc.)
- Bash Shell
- Necessary dependencies like `git`, `curl`, `unzip`, etc.

## Features

### Server Management

- **Server Creation**: Quickly create new FiveM server instances with customizable configurations, including server name, resources, server data path, server port, and more.
- **Server Start**: Start a designated FiveM server instance with a single command.
- **Server Stop**: Gracefully shut down a running FiveM server to ensure data integrity.
- **Server Restart**: Restart a running FiveM server instance without interrupting gameplay.
- **Server Update**: Automatically update the FiveM server resources to the latest versions available.

### Monitoring and Logging

- **Real-time Console Output**: View live console output from the FiveM server to monitor player activity, server performance, and debug issues in real-time.
- **Server Logs**: Access and analyze comprehensive server logs to track player actions, server events, errors, and more.

### Security Enhancements

- **Firewall Configuration**: Configure firewall rules to restrict access to the FiveM server and enhance security.
- **SSH Hardening**: Implement best practices to secure SSH access to the server, including key-based authentication, disabling root login, and more.
- **Automatic Security Updates**: Automatically apply security updates to the server operating system and installed packages to mitigate potential vulnerabilities.
- **Fail2Ban Integration**: Set up Fail2Ban to prevent brute-force attacks and protect against unauthorized access attempts.

### Backup and Recovery

- **Server Backup**: Schedule automatic backups of the FiveM server data, including server configuration, resources, player data, and more, to ensure data integrity and disaster recovery.
- **Backup Management**: Easily manage and restore server backups from a centralized interface.

### Script Management

- **Automatic Updates**: Check for and apply updates to the management script itself to ensure access to the latest features, bug fixes, and improvements.
- **Customization Options**: Customize script behavior and configurations to suit your specific requirements and preferences.
- **Extensibility**: Easily extend the script's functionality through modular design and integration with third-party tools and services.

## Contributions

Contributions to this script are highly encouraged! If you encounter any bugs, have feature requests, or want to contribute improvements, feel free to open an issue or submit a pull request on GitHub.

## License

This script is licensed under the [MIT License](LICENSE).

## Disclaimer

This script is provided as-is, without any warranty or guarantee. Use it at your own risk.
