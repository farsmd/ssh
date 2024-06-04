#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Required packages
required_packages=("curl" "tc" "iptables" "vnstat" "psmisc")

# Function to check if a package is installed
is_package_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to install missing packages
install_missing_packages() {
    echo -e "${YELLOW}Checking for required packages...${NC}"

    for package in "${required_packages[@]}"; do
        if is_package_installed "$package"; then
            echo -e "${GREEN}$package is already installed.${NC}"
        else
            echo -e "${YELLOW}$package is not installed. Installing...${NC}"
            apt-get update
            apt-get install -y "$package"
            if is_package_installed "$package"; then
                echo -e "${GREEN}$package installed successfully.${NC}"
            else
                echo -e "${RED}Failed to install $package. Please install it manually.${NC}"
                exit 1
            fi
        fi
    done
}

# Function to check for root privileges
check_root_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script must be run as root. Please use sudo.${NC}"
        exit 1
    fi
}

# Main function to check and prepare the server
prepare_server() {
    # Check for root privileges
    check_root_privileges

    # Install missing packages
    install_missing_packages

    echo -e "${GREEN}Server is ready for running the user management script.${NC}"
}

# Execute the main function
prepare_server
