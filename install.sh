#!/bin/bash

# URL to the script on GitHub
SCRIPT_URL="https://raw.githubusercontent.com/farsmd/ssh/main/user_management.sh"

# Download the script
curl -O $SCRIPT_URL

# Make the script executable
sudo mv user_management.sh /usr/local/bin/ums
chmod +x user_management.sh

# Run the script
./user_management.sh
