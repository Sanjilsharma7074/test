#!/bin/bash

LOG_FILE="/home/$USER/user_management.log"

# Function to check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        whiptail --title "Permission Denied" --msgbox "This script must be run as root!" 10 50
        exit 1
    fi
}

# Function to log actions
log_action() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to validate username (no special chars)
validate_username() {
    if [[ "$1" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Add a system user
add_system_user() {
    username=$(whiptail --inputbox "Enter new username:" 10 50 3>&1 1>&2 2>&3)

    if ! validate_username "$username"; then
        whiptail --msgbox "Invalid username format." 8 40
        return
    fi

    if id "$username" &>/dev/null; then
        whiptail --msgbox "User already exists!" 8 40
        return
    fi

    password=$(whiptail --passwordbox "Enter password for $username:" 10 50 3>&1 1>&2 2>&3)
    home_dir=$(whiptail --inputbox "Enter home directory (optional):" 10 50 "/home/$username" 3>&1 1>&2 2>&3)

    useradd -m -d "$home_dir" "$username"
    echo "$username:$password" | chpasswd

    whiptail --msgbox "User $username added successfully!" 8 50
    log_action "User added: $username"
}

# Delete a system user
delete_system_user() {
    username=$(whiptail --inputbox "Enter username to delete:" 10 50 3>&1 1>&2 2>&3)

    if ! id "$username" &>/dev/null; then
        whiptail --msgbox "User does not exist." 8 40
        return
    fi

    if whiptail --yesno "Are you sure you want to delete $username?" 10 50; then
        userdel -r "$username"
        whiptail --msgbox "User $username deleted." 8 40
        log_action "User deleted: $username"
    else
        whiptail --msgbox "Deletion cancelled." 8 40
    fi
}

# Modify user details
modify_system_user() {
    username=$(whiptail --inputbox "Enter username to modify:" 10 50 3>&1 1>&2 2>&3)

    if ! id "$username" &>/dev/null; then
        whiptail --msgbox "User does not exist." 8 40
        return
    fi

    OPTION=$(whiptail --title "Modify User" --menu "Choose field to modify" 15 60 4 \
        "1" "Change username" \
        "2" "Change password" \
        "3" "Change home directory" \
        "4" "Change group" 3>&1 1>&2 2>&3)

    case $OPTION in
        1)
            new_name=$(whiptail --inputbox "Enter new username:" 10 50 3>&1 1>&2 2>&3)
            usermod -l "$new_name" "$username"
            whiptail --msgbox "Username changed from $username to $new_name." 8 50
            log_action "Username changed from $username to $new_name"
            ;;
        2)
            password=$(whiptail --passwordbox "Enter new password for $username:" 10 50 3>&1 1>&2 2>&3)
            echo "$username:$password" | chpasswd
            whiptail --msgbox "Password updated." 8 40
            log_action "Password changed for $username"
            ;;
        3)
            new_home=$(whiptail --inputbox "Enter new home directory:" 10 50 3>&1 1>&2 2>&3)
            usermod -d "$new_home" -m "$username"
            whiptail --msgbox "Home directory updated." 8 50
            log_action "Home directory changed for $username to $new_home"
            ;;
        4)
            new_group=$(whiptail --inputbox "Enter new group name:" 10 50 3>&1 1>&2 2>&3)
            groupadd "$new_group" 2>/dev/null
            usermod -g "$new_group" "$username"
            whiptail --msgbox "Group updated." 8 40
            log_action "Group changed for $username to $new_group"
            ;;
    esac
}

# List users
list_system_users() {
    awk -F: '{ if ($3 >= 1000 && $1 != "nobody") print $1 }' /etc/passwd > /tmp/userlist.txt
    whiptail --textbox /tmp/userlist.txt 20 60
    rm -f /tmp/userlist.txt
}

# Main Menu
main_menu() {
    while true; do
        CHOICE=$(whiptail --title "Linux User Management System" --menu "Choose an option:" 20 60 10 \
            "1" "Add User" \
            "2" "Delete User" \
            "3" "Modify User" \
            "4" "List Users" \
            "5" "Exit" 3>&1 1>&2 2>&3)

        case $CHOICE in
            1) add_system_user ;;
            2) delete_system_user ;;
            3) modify_system_user ;;
            4) list_system_users ;;
            5) exit ;;
            *) whiptail --msgbox "Invalid option. Try again." 8 40 ;;
        esac
    done
}

# Run script
check_root
main_menu
