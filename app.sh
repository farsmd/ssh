#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Define groups and their bandwidth limits
declare -A group_bandwidth
group_bandwidth=(["group1"]="1mbit" ["group2"]="500kbit" ["group3"]="250kbit")

# Function to add a new user and assign to a group
add_user() {
    echo "Enter username:"
    read username
    echo "Enter password:"
    read -s password
    echo "Enter group (group1, group2, group3):"
    read group

    # Check if group is valid
    if [[ -z "${group_bandwidth[$group]}" ]]; then
        echo -e "${RED}Invalid group. Please choose from group1, group2, group3.${NC}"
        return
    fi

    # Create user and set password
    useradd -m "$username"
    echo "$username:$password" | chpasswd

    # Assign user to group
    usermod -aG "$group" "$username"

    # Set default expiration and connection limits
    chage -E $(date -d "+30 days" +%Y-%m-%d) "$username"
    echo "MaxSessions 2" >> /etc/ssh/sshd_config

    # Log user addition
    logger "User $username added to $group with default 30 days expiration and 2 simultaneous connections."

    # Apply bandwidth limit
    apply_bandwidth_limit "$username" "$group"

    # Restart SSH service
    systemctl restart sshd

    echo -e "${GREEN}User $username added to $group with default 30 days expiration and 2 simultaneous connections.${NC}"
}

# Function to apply bandwidth limit to a user
apply_bandwidth_limit() {
    username=$1
    group=$2
    bandwidth=${group_bandwidth[$group]}

    # Get user's IP address (assuming a single interface, e.g., eth0)
    user_ip=$(getent hosts "$username" | awk '{ print $1 }')

    # Apply traffic control rules using tc and iptables
    tc qdisc add dev eth0 root handle 1: htb default 10
    tc class add dev eth0 parent 1: classid 1:1 htb rate "$bandwidth"
    iptables -A OUTPUT -t mangle -p tcp -m owner --uid-owner "$username" -j MARK --set-mark 1
    iptables -A POSTROUTING -t mangle -o eth0 -m mark --mark 1 -j RETURN
}

# Function to add multiple users from a file
add_users_bulk() {
    echo "Enter the file path with users data:"
    read file_path

    if [[ -f "$file_path" ]]; then
        while IFS=',' read -r username password group; do
            if [[ -z "${group_bandwidth[$group]}" ]]; then
                echo -e "${RED}Invalid group for user $username. Skipping.${NC}"
                continue
            fi
            useradd -m "$username"
            echo "$username:$password" | chpasswd
            usermod -aG "$group" "$username"
            chage -E $(date -d "+30 days" +%Y-%m-%d) "$username"
            apply_bandwidth_limit "$username" "$group"
            logger "User $username added to $group with default 30 days expiration and 2 simultaneous connections."
        done < "$file_path"

        # Restart SSH service
        systemctl restart sshd
        echo -e "${GREEN}Users from $file_path added successfully.${NC}"
    else
        echo -e "${RED}File not found.${NC}"
    fi
}

# Function to edit a user
edit_user() {
    echo "Enter username to edit:"
    read username

    echo "1. Extend expiration"
    echo "2. Change connection limits"
    echo "3. Change password"
    echo "4. Change group"
    read -p "Select an option: " option

    if [ "$option" -eq 1 ]; then
        echo "Enter additional days:"
        read days
        chage -E $(date -d "+$days days" +%Y-%m-%d) "$username"
        logger "Expiration extended for $username."
        echo -e "${GREEN}Expiration extended for $username.${NC}"
    elif [ "$option" -eq 2 ]; then
        echo "Enter new connection limit:"
        read limit
        sed -i "/MaxSessions/c\MaxSessions $limit" /etc/ssh/sshd_config
        systemctl restart sshd
        logger "Connection limit changed for $username."
        echo -e "${GREEN}Connection limit changed for $username.${NC}"
    elif [ "$option" -eq 3 ]; then
        echo "Enter new password:"
        read -s password
        echo "$username:$password" | chpasswd
        logger "Password changed for $username."
        echo -e "${GREEN}Password changed for $username.${NC}"
    elif [ "$option" -eq 4 ]; then
        echo "Enter new group (group1, group2, group3):"
        read group
        if [[ -z "${group_bandwidth[$group]}" ]]; then
            echo -e "${RED}Invalid group. Please choose from group1, group2, group3.${NC}"
            return
        fi
        old_group=$(id -Gn "$username" | grep -oP '\bgroup\d\b')
        gpasswd -d "$username" "$old_group"
        usermod -aG "$group" "$username"
        apply_bandwidth_limit "$username" "$group"
        logger "Group changed for $username from $old_group to $group."
        echo -e "${GREEN}Group changed for $username from $old_group to $group.${NC}"
    else
        echo -e "${RED}Invalid option.${NC}"
    fi
}

# Function to delete a user
delete_user() {
    echo "Enter username to delete:"
    read username

    userdel -r "$username"
    logger "User $username deleted."
    echo -e "${GREEN}User $username deleted.${NC}"
}

# Function to show online users
show_online_users() {
    echo -e "${YELLOW}Online users:${NC}"
    who

    echo -e "${YELLOW}User connection details:${NC}"
    netstat -tnpa | grep 'ESTABLISHED.*sshd'
}

# Function to show user traffic usage
show_traffic_usage() {
    echo -e "${YELLOW}Traffic usage for users:${NC}"
    for user in $(ls /home); do
        echo -e "${GREEN}Traffic usage for $user:${NC}"
        vnstat -u -i eth0 -u "$user"
        vnstat -m -i eth0 -u "$user"
    done
}

# Function to show CPU and memory usage for each user
show_cpu_memory_usage() {
    echo -e "${YELLOW}CPU and memory usage for users:${NC}"
    for user in $(ls /home); do
        echo -e "${GREEN}Usage for $user:${NC}"
        ps -u "$user" -o pid,%cpu,%mem,cmd
    done
}

# Function to show logs
show_logs() {
    echo -e "${YELLOW}Connection logs:${NC}"
    grep 'Accepted' /var/log/auth.log

    echo -e "${YELLOW}Disconnection logs:${NC}"
    grep 'Disconnected' /var/log/auth.log
}

# Function to backup user data and configuration
backup_data() {
    echo "Enter backup file path:"
    read backup_file

    tar -czf "$backup_file" /etc/passwd /etc/shadow /etc/group /etc/gshadow /home /etc/ssh/sshd_config
    logger "Backup completed at $backup_file."
    echo -e "${GREEN}Backup completed at $backup_file.${NC}"
}

# Function to restore user data and configuration
restore_data() {
    echo "Enter backup file path:"
    read backup_file

    if [[ -f "$backup_file" ]]; then
        tar -xzf "$backup_file" -C /
        systemctl restart sshd
        logger "Restore completed from $backup_file."
        echo -e "${GREEN}Restore completed from $backup_file.${NC}"
    else
        echo -e "${RED}Backup file not found.${NC}"
    fi
}

# Function to change SSH port
change_ssh_port() {
    echo "Enter new SSH port:"
    read new_port

    if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid port number.${NC}"
        return
    fi

    # Update SSH configuration file
    sed -i "/^#Port 22/c\Port $new_port" /etc/ssh/sshd_config
    sed -i "/^Port [0-9]*$/c\Port $new_port" /etc/ssh/sshd_config

    # Restart SSH service
    systemctl restart sshd
    logger "SSH port changed to $new_port."
    echo -e "${GREEN}SSH port changed to $new_port.${NC}"
}

# Main menu
while true; do
    echo "1. Add User"
    echo "2. Add Users in Bulk"
    echo "3. Edit User"
    echo "4. Delete User"
    echo "5. Show Online Users"
    echo "6. Show Traffic Usage"
    echo "7. Show CPU and Memory Usage"
    echo "8. Show Logs"
    echo "9. Backup Data"
    echo "10. Restore Data"
    echo "11. Change SSH Port"
    echo "12. Exit"
    read -p "Select an option: " option

    case $option in
        1) add_user ;;
        2) add_users_bulk ;;
        3) edit_user ;;
        4) delete_user ;;
        5) show_online_users ;;
        6) show_traffic_usage ;;
        7) show_cpu_memory_usage ;;
        8) show_logs ;;
        9) backup_data ;;
        10) restore_data ;;
        11) change_ssh_port ;;
        12) exit ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
done
