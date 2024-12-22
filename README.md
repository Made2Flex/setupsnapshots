# Setup Snapshots

## Overview

`setupsnapshots` is a Bash script designed to simplify the setup of BTRFS snapshots on Linux systems. This script automates the installation of necessary packages, configuration of services, and creation of snapshot directories, ensuring a smooth and efficient backup process.

## Features

- Detects the package manager (Arch-based or Debian-based).
- Installs Timeshift and its dependencies.
- Configures Timeshift for BTRFS snapshots.
- Enables necessary services for snapshot management.
- Provides user-friendly prompts for configuration options.

## Requirements

- A Linux distribution with BTRFS support.
- Bash shell.
- Sudo privileges for installing packages and modifying system configurations.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/YourRepo/setupsnapshots.git
   cd setupsnapshots
   ```

2. Make the script executable:

   ```bash
   chmod +x setupsnapshots.sh
   ```

## Usage

To run the setup script, execute the following command:

sudo ./setupsnapshots.sh

## Contributing

Contributions are welcome! If you have suggestions for improvements or new features, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
