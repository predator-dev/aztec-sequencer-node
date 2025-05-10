# Aztec Sequencer Node Manager

A user-friendly management script for the Aztec Sequencer Node.

## Overview

This script simplifies the process of installing, running, and maintaining an Aztec Sequencer Node. It provides a convenient menu-driven interface to perform all necessary operations without having to remember complex commands.

## Features

- **One-Command Installation**: Simple setup of the Aztec Sequencer Node
- **Node Management**: Start, stop, and check node status easily
- **Real-time Logs**: View node logs with a simple command
- **Automated Backups**: Create and restore backups of your node data
- **System Monitoring**: Check resource usage and system requirements
- **Clean Interface**: User-friendly menu-driven interface

## Installation

To install the Aztec Sequencer Node Manager, run the following command:

```bash
curl -sSL -o aztec.sh https://raw.githubusercontent.com/predator-dev/aztec-sequencer-node/main/aztec.sh && chmod +x aztec.sh && ./aztec.sh
```

## Usage

1. Run the script: `./aztec.sh`
2. Select the desired option from the menu:
   - Install/Update Aztec Sequencer Node
   - Start Node
   - Stop Node
   - Check Node Status
   - View Node Logs
   - Backup Node Data
   - Restore Node Data
   - Update Node Software
   - Monitor System Resources
   - Show Node Information
   - Cleanup Old Data and Logs
   - Check System Requirements
   - Exit

## Requirements

- Linux-based operating system (Ubuntu recommended)
- Minimum 4 CPU cores (recommended)
- Minimum 8GB RAM (recommended)
- At least 50GB free disk space
- Docker and Docker Compose installed (the script will install these if missing)

## Backups

The script automatically creates backups when updating the node. Backups are stored in the `~/aztec-node-backup` directory. You can manually create backups by selecting the "Backup Node Data" option from the menu.

## Troubleshooting

If you encounter any issues:

1. Check the node logs by selecting "View Node Logs" from the menu
2. Ensure your system meets the minimum requirements
3. Try stopping and starting the node
4. Restore from a backup if necessary

## Credits

- Based on the official Aztec Sequencer Node repository: [Jaytechent/Aztec-Sequencer-Node](https://github.com/Jaytechent/Aztec-Sequencer-Node)
- Inspired by community tools that simplify node management

## License

This project is open source and available under the MIT License.
