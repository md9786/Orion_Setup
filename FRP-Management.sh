#!/bin/bash

# FRP Management Script
# Manages FRP client and server instances for ports 42420-42424 and EFRP service

# Define color codes for a modern look
BLUE='\033[0;34m'    # Regular Blue for logs
GREEN='\033[0;32m'   # Regular Green for start messages
RED='\033[0;31m'     # Regular Red for stop messages
YELLOW='\033[1;33m'  # Bright Yellow for highlights
CYAN='\033[1;36m'
PURPLE='\033[0;35m'
NC='\033[0m'         # No Color

# Function to check FRP client logs
logs_frpc() {
    echo -e "${BLUE}Checking FRP client logs...${NC}"
    for i in {42420..42424}; do
        echo -e "${YELLOW}Logs for frpc@client-$i:${NC}"
        journalctl -u frpc@client-$i -n 3 --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to check FRP server logs
logs_frps() {
    echo -e "${BLUE}Checking FRP server logs...${NC}"
    for i in {42420..42424}; do
        echo -e "${YELLOW}Logs for frps@server-$i:${NC}"
        journalctl -u frps@server-$i -n 3 --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to check EFRP logs
logs_efrp() {
    echo -e "${BLUE}Showing EFRP service logs...${NC}"
    journalctl -u EFRP.service -e -f | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
    echo ""
}

# Function to check extended FRP client logs
logs_frpc_extended() {
    echo -e "${BLUE}Checking extended FRP client logs (last 200 lines)...${NC}"
    for i in {42420..42424}; do
        echo -e "${YELLOW}Extended logs for frpc@client-$i:${NC}"
        journalctl -u frpc@client-$i -n 200 --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to check extended FRP server logs
logs_frps_extended() {
    echo -e "${BLUE}Checking extended FRP server logs (last 200 lines)...${NC}"
    for i in {42420..42424}; do
        echo -e "${YELLOW}Extended logs for frps@server-$i:${NC}"
        journalctl -u frps@server-$i -n 200 --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to start FRP clients
start_frpc() {
    echo -e "${GREEN}Starting FRP clients...${NC}"
    for i in {42420..42424}; do
        if systemctl start frpc@client-$i; then
            echo -e "${GREEN}Started frpc@client-$i${NC}"
        else
            echo -e "${RED}Failed to start frpc@client-$i${NC}"
        fi
        systemctl status frpc@client-$i --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to stop FRP clients
stop_frpc() {
    echo -e "${RED}Stopping FRP clients...${NC}"
    for i in {42420..42424}; do
        if systemctl stop frpc@client-$i; then
            echo -e "${RED}Stopped frpc@client-$i${NC}"
        else
            echo -e "${RED}Failed to stop frpc@client-$i${NC}"
        fi
        systemctl status frpc@client-$i --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to start FRP servers
start_frps() {
    echo -e "${GREEN}Starting FRP servers...${NC}"
    for i in {42420..42424}; do
        if systemctl start frps@server-$i; then
            echo -e "${GREEN}Started frps@server-$i${NC}"
        else
            echo -e "${RED}Failed to start frps@server-$i${NC}"
        fi
        systemctl status frps@server-$i --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to stop FRP servers
stop_frps() {
    echo -e "${RED}Stopping FRP servers...${NC}"
    for i in {42420..42424}; do
        if systemctl stop frps@server-$i; then
            echo -e "${RED}Stopped frps@server-$i${NC}"
        else
            echo -e "${RED}Failed to stop frps@server-$i${NC}"
        fi
        systemctl status frps@server-$i --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to start EFRP service
start_efrp() {
    echo -e "${GREEN}Enabling and starting EFRP service...${NC}"
    if systemctl enable EFRP.service && systemctl start EFRP.service; then
        echo -e "${GREEN}EFRP service started and enabled successfully${NC}"
    else
        echo -e "${RED}Failed to start or enable EFRP service${NC}"
    fi
    echo ""
}

# Function to stop EFRP service
stop_efrp() {
    echo -e "${RED}Stopping and disabling EFRP service...${NC}"
    if systemctl stop EFRP.service && systemctl disable EFRP.service; then
        echo -e "${RED}EFRP service stopped and disabled successfully${NC}"
    else
        echo -e "${RED}Failed to stop or disable EFRP service${NC}"
    fi
    echo ""
}

# Main menu
while true; do
    clear
    echo -e " ${PURPLE}.d88888b.          d8b                         888     888 8888888b.  888b    888 "
    echo -e " ${PURPLE}d88P^ ^Y88b         Y8P                         888     888 888   Y88b 8888b   888 "
    echo -e " ${PURPLE}888     888                                     888     888 888    888 88888b  888 "
    echo -e " ${PURPLE}888     888 888d888 888  .d88b.  88888b.        Y88b   d88P 888   d88P 888Y88b 888 "
    echo -e " ${PURPLE}888     888 888P^   888 d88^^88b 888 ^88b        Y88b d88P  8888888P^  888 Y88b888 "
    echo -e " ${PURPLE}888     888 888     888 888  888 888  888         Y88o88P   888        888  Y88888 "
    echo -e " ${PURPLE}Y88b. .d88P 888     888 Y88..88P 888  888          Y888P    888        888   Y8888 "
    echo -e " ${PURPLE} ^Y88888P^  888     888  ^Y88P^  888  888           Y8P     888        888    Y888 "
    echo ""

    echo -e "${BLUE}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│                                                  │${NC}"
    echo -e "${BLUE}│          FRP Management Tool                     │${NC}"
    echo -e "${BLUE}│                                                  │${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${GREEN}Available Options:${NC}"
    echo -e "${YELLOW}  [1]  Check FRP client logs${NC}"
    echo -e "${YELLOW}  [2]  Check FRP server logs${NC}"
    echo -e "${YELLOW}  [3]  Check EFRP service logs${NC}"
    echo -e "${GREEN}  [4]  Start FRP clients${NC}"
    echo -e "${RED}  [5]  Stop FRP clients${NC}"
    echo -e "${GREEN}  [6]  Start FRP servers${NC}"
    echo -e "${RED}  [7]  Stop FRP servers${NC}"
    echo -e "${GREEN}  [8]  Start EFRP service${NC}"
    echo -e "${RED}  [9]  Stop EFRP service${NC}"
    echo -e "${CYAN}  [10] Check extended FRP client logs${NC}"
    echo -e "${CYAN}  [11] Check extended FRP server logs${NC}"
    echo -e "${RED}  [12] Exit${NC}"
    echo ""
    echo -e "${BLUE}──────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}Enter your choice (1-12):${NC} \c"
    read choice

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
        10) logs_frpc_extended ;;
        11) logs_frps_extended ;;
        12) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option, please select 1-12${NC}" ;;
    esac
    echo ""
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -s
done
