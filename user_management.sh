#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to add a new user with expiration days and bandwidth limit
add_user() {
    read -p "Enter username: " username
    read -p "Enter password: " password
    read -p "Enter number of days until expiration from first login: " expire_days
    read -p "Enter bandwidth limit (e.g., 1mbit): " bandwidth_limit

    sudo useradd -m $username
    echo "$username:$password" | sudo chpasswd
    sudo chage -d 0 -M $expire_days $username  # Set password to expire after the specified days

    # Limit network usage
    sudo wondershaper -a eth0 -u $bandwidth_limit -d $bandwidth_limit

    echo -e "${GREEN}User $username added successfully with expiration of $expire_days days and bandwidth limit of $bandwidth_limit.${NC}"
}

# Function to configure SSH tunnel for a user
configure_ssh_tunnel() {
    read -p "Enter username: " username
    read -p "Enter local port (default 3306): " local_port
    read -p "Enter remote port (default 3306): " remote_port

    # Set default ports if not provided
    local_port=${local_port:-3306}
    remote_port=${remote_port:-3306}

    sudo mkdir -p /home/$username/.ssh
    echo "ssh -L $local_port:localhost:$remote_port $username@localhost" > /home/$username/.ssh/tunnel.sh
    sudo chmod +x /home/$username/.ssh/tunnel.sh
    echo -e "${GREEN}SSH tunnel script created for user $username with local port $local_port and remote port $remote_port.${NC}"
}

# Function to display active users, expiration date, and network usage
display_active_users() {
    echo -e "${BLUE}Active Users:${NC}"
    for user in $(cut -d: -f1 /etc/passwd); do
        expire_date=$(sudo chage -l $user | grep "Account expires" | cut -d: -f2)
        if [ "$expire_date" != " never" ]; then
            days_left=$(($(date -d "$expire_date" +%s) - $(date +%s)))
            days_left=$((days_left / 86400))
            usage=$(vnstat -i eth0 --oneline | cut -d\; -f9)
            echo -e "${YELLOW}User: $user, Days left: $days_left, Network usage: $usage${NC}"
        fi
    done
}

# Function to display online users
display_online_users() {
    echo -e "${BLUE}Online Users:${NC}"
    who
}

# Function to update the script from GitHub
update_script() {
    echo -e "${YELLOW}Updating the script from GitHub...${NC}"
    sudo git pull origin main
    echo -e "${GREEN}Script updated successfully.${NC}"
}

# Function to backup user data
backup_data() {
    echo -e "${YELLOW}Backing up user data...${NC}"
    sudo tar -czvf user_backup.tar.gz /home/*
    echo -e "${GREEN}User data backed up successfully to user_backup.tar.gz.${NC}"
}

# Function to restore user data
restore_data() {
    echo -e "${YELLOW}Restoring user data...${NC}"
    sudo tar -xzvf user_backup.tar.gz -C /
    echo -e "${GREEN}User data restored successfully.${NC}"
}

# Main menu
while true; do
    echo -e "${RED}User Management Script${NC}"
    echo -e "${GREEN}1. Add User${NC}"
    echo -e "${GREEN}2. Configure SSH Tunnel${NC}"
    echo -e "${GREEN}3. Display Active Users${NC}"
    echo -e "${GREEN}4. Display Online Users${NC}"
    echo -e "${GREEN}5. Update Script${NC}"
    echo -e "${GREEN}6. Backup Data${NC}"
    echo -e "${GREEN}7. Restore Data${NC}"
    echo -e "${GREEN}8. Exit${NC}"
    read -p "${BLUE}Choose an option: ${NC}" choice

    case $choice in
        1)
            add_user
            ;;
        2)
            configure_ssh_tunnel
            ;;
        3)
            display_active_users
            ;;
        4)
            display_online_users
            ;;
        5)
            update_script
            ;;
        6)
            backup_data
            ;;
        7)
            restore_data
            ;;
        8)
            exit 0
            ;;
        *)
            echo "Invalid option, please try again."
            ;;
    esac
done
