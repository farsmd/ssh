#!/bin/bash

# URL to the script on GitHub
SCRIPT_URL="https://raw.githubusercontent.com/farsmd/ssh/main/app-ums.sh"
SCRIPT_URL2="https://raw.githubusercontent.com/farsmd/ssh/main/required.sh"
# Download the script
curl -O $SCRIPT_URL
curl -O $SCRIPT_URL2
chmod +x required.sh
chmod +x app-ums.sh
bash required.sh
# Make the script executable
echo "alias ums='bash ~/ums/app-ums.sh'" >> ~/.bashrc
source ~/.bashrc

echo "Installation completed. Use 'ums' to manage users."
