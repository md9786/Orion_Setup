#!/bin/bash

# FRP Management Script
# Manages FRP client and server instances for ports 42420-42424 and EFRP service

# Function to check FRP client logs
logs_frpc() {
    echo "Checking FRP client logs..."
    for i in {42420..42424}; do
        echo "Logs for frpc@client-$i:"
        journalctl -u frpc@client-$i -n 3 --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to check FRP server logs
logs_frps() {
    echo "Checking FRP server logs..."
    for i in {42420..42424}; do
        echo "Logs for frps@server-$i:"
        journalctl -u frps@server-$i -n 3 --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to check EFRP logs
logs_efrp() {
    echo "Showing EFRP service logs..."
    journalctl -u EFRP.service -e -f | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
    echo ""
}

# Function to start FRP clients
start_frpc() {
    echo "Starting FRP clients..."
    for i in {42420..42424}; do
        systemctl start frpc@client-$i && echo "Started frpc@client-$i" || echo "Failed to start frpc@client-$i"
        systemctl status frpc@client-$i --no-pager | grep "Active:"
        echo ""
    done
}

# Function to stop FRP clients
stop_frpc() {
    echo "Stopping FRP clients..."
    for i in {42420..42424}; do
        systemctl stop frpc@client-$i && echo "Stopped frpc@client-$i" || echo "Failed to stop frpc@client-$i"
        systemctl status frpc@client-$i --no-pager | grep "Active:"
        echo ""
    done
}

# Function to start FRP servers
start_frps() {
    echo "Starting FRP servers..."
    for i in {42420..42424}; do
        systemctl start frps@server-$i && echo "Started frps@server-$i" || echo "Failed to start frps@server-$i"
        systemctl status frps@server-$i --no-pager | grep "Active:"
        echo ""
    done
}

# Function to stop FRP servers
stop_frps() {
    echo "Stopping FRP servers..."
    for i in {42420..42424}; do
        systemctl stop frps@server-$i && echo "Stopped frps@server-$i" || echo "Failed to stop frps@server-$i"
        systemctl status frps@server-$i --no-pager | grep "Active:"
        echo ""
    done
}

# Function to start EFRP service
start_efrp() {
    echo "Enabling and starting EFRP service..."
    systemctl enable EFRP.service && systemctl start EFRP.service
    echo ""
}

# Function to stop EFRP service
stop_efrp() {
    echo "Stopping and disabling EFRP service..."
    systemctl stop EFRP.service && systemctl disable EFRP.service
    echo ""
}

# Main menu
while true; do
    echo " .d88888b.          d8b                         888     888 8888888b.  888b    888 "
    echo "d88P^ ^Y88b         Y8P                         888     888 888   Y88b 8888b   888 "
    echo "888     888                                     888     888 888    888 88888b  888 "
    echo "888     888 888d888 888  .d88b.  88888b.        Y88b   d88P 888   d88P 888Y88b 888 "
    echo "888     888 888P^   888 d88^^88b 888 ^88b        Y88b d88P  8888888P^  888 Y88b888 "
    echo "888     888 888     888 888  888 888  888         Y88o88P   888        888  Y88888 "
    echo "Y88b. .d88P 888     888 Y88..88P 888  888          Y888P    888        888   Y8888 "
    echo " ^Y88888P^  888     888  ^Y88P^  888  888           Y8P     888        888    Y888 "
    echo ""
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}       FRP Management Tool       ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
    echo "FRP Management Script"
    echo "1. Check FRP client logs"
    echo "2. Check FRP server logs"
    echo "3. Check EFRP service logs"
    echo "4. Start FRP clients"
    echo "5. Stop FRP clients"
    echo "6. Start FRP servers"
    echo "7. Stop FRP servers"
    echo "8. Start EFRP service"
    echo "9. Stop EFRP service"
    echo "10. Exit"
    read -p "Select an option (1-10): " choice

    case $choice in
        1) logs_frpc ;;
        2) logs_frps ;;
        3) logs_efrp ;;
        4) start_frpc ;;
        5) stop_frpc ;;
        6) start_frps ;;
        7) stop_frps ;;
        8) start_efrp ;;
        9) stop_efrp ;;
        10) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option, please select 1-10" ;;
    esac
    echo ""
done
