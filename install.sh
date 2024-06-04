#!/bin/bash

# URL to the script on GitHub
SCRIPT_URL="https://raw.githubusercontent.com/farsmd/ssh/main/app-ums.sh"
SCRIPT_URL2="https://raw.githubusercontent.com/farsmd/ssh/main/required.sh"
# Download the script
curl -O $SCRIPT_URL
curl -O $SCRIPT_URL2
chmod +x required.sh
# Make the script executable
sudo mv app-ums.sh /usr/local/bin/ums
chmod +x app-ums.sh

echo "Installation completed. Use 'ums' to manage users."
