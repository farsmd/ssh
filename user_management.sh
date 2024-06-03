#!/bin/bash

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

    echo "User $username added successfully with expiration of $expire_days days and bandwidth limit of $bandwidth_limit."
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
    echo "SSH tunnel script created for user $username with local port $local_port and remote port $remote_port."
}

# Function to display active users, expiration date, and network usage
display_active_users() {
    echo "Active Users:"
    for user in $(cut -d: -f1 /etc/passwd); do
        expire_date=$(sudo chage -l $user | grep "Account expires" | cut -d: -f2)
        if [ "$expire_date" != " never" ]; then
            days_left=$(($(date -d "$expire_date" +%s) - $(date +%s)))
            days_left=$((days_left / 86400))
            usage=$(vnstat -i eth0 --oneline | cut -d\; -f9)
            echo "User: $user, Days left: $days_left, Network usage: $usage"
        fi
    done
}

# Function to display online users
display_online_users() {
    echo "Online Users:"
    who
}

# Function to update the script from GitHub
update_script() {
    echo "Updating the script from GitHub..."
    sudo git pull origin main
    echo "Script updated successfully."
}

# Function to backup user data
backup_data() {
    echo "Backing up user data..."
    sudo tar -czvf user_backup.tar.gz /home/*
    echo "User data backed up successfully to user_backup.tar.gz."
}

# Function to restore user data
restore_data() {
    echo "Restoring user data..."
    sudo tar -xzvf user_backup.tar.gz -C /
    echo "User data restored successfully."
}

# Main menu
while true; do
    echo "User Management Script (UMS)"
    echo "1. Add User"
    echo "2. Configure SSH Tunnel"
    echo "3. Display Active Users"
    echo "4. Display Online Users"
    echo "5. Update Script"
    echo "6. Backup Data"
    echo "7. Restore Data"
    echo "8. Exit"
    read -p "Choose an option: " choice

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
