#!/bin/bash

# URL to the script on GitHub
SCRIPT_URL="https://raw.githubusercontent.com/farsmd/ssh/main/ssh-user-manager.sh"

# Download the script
curl -O $SCRIPT_URL

# Make the script executable
chmod +x user_management.sh

# Run the script
./user_management.sh
