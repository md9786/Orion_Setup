#!/bin/bash
# =========================================================
# Combined Script - Ubuntu Mirror & DNS Optimizer
# Developed by Ali Nezamifar | Powered by Bia2Host.Com
# =========================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ASCII Art Watermark (Bia2Host)
show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
██████╗ ██╗ █████╗ ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
██╔══██╗██║██╔══██╗╚════██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
██████╔╝██║███████║ █████╔╝███████║██║   ██║███████╗   ██║   
██╔══██╗██║██╔══██║██╔═══╝ ██╔══██║██║   ██║╚════██║   ██║   
██████╔╝██║██║  ██║███████╗██║  ██║╚██████╔╝███████║   ██║   
╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   

                    B I A 2 H O S T
------------------------------------------------------------
 Developed by Ali Nezamifar | Powered by Bia2Host.Com
------------------------------------------------------------
EOF
    echo -e "${NC}"
}

# Function to optimize Ubuntu mirrors
optimize_mirrors() {
    echo -e "\n${BLUE}=== Optimizing Ubuntu Mirrors ===${NC}\n"
    
    # List of mirrors
    mirrors=(
        "https://ubuntu.pishgaman.net/ubuntu"
        "http://mirror.aminidc.com/ubuntu"
        "https://ubuntu.pars.host"
        "https://ir.ubuntu.sindad.cloud/ubuntu"
        "https://ubuntu.shatel.ir/ubuntu"
        "https://ubuntu.mobinhost.com/ubuntu"
        "https://mirror.iranserver.com/ubuntu"
        "https://mirror.arvancloud.ir/ubuntu"
        "http://ir.archive.ubuntu.com/ubuntu"
        "https://ubuntu.parsvds.com/ubuntu/"
    )

    # Function to measure download speed
    measure_speed() {
        local url=$1
        local output=$(wget --timeout=5 --tries=1 -O /dev/null "$url" 2>&1 | grep -o '[0-9.]* [KM]B/s' | tail -1)

        if [[ -z $output ]]; then
            echo -1
        else
            if [[ $output == *K* ]]; then
                echo "$(echo "$output" | sed 's/ KB\/s//')"
            elif [[ $output == *M* ]]; then
                echo "$(echo "scale=2; $(echo "$output" | sed 's/ MB\/s//') * 1024" | bc)"
            fi
        fi
    }

    # Variables to store the fastest mirror
    best_mirror=""
    best_speed=0

    # Print table header
    echo -e "${BLUE}Mirror URL | Download Speed (KB/s)${NC}"
    echo -e "--------------------------------------------"

    # Check download speed from each mirror
    for mirror in "${mirrors[@]}"; do
        speed=$(measure_speed "$mirror")

        if [[ $speed == -1 ]]; then
            echo -e "${CYAN}$mirror${WHITE} | ${RED}Failed to connect${NC}"
            continue
        fi

        echo -e "${CYAN}$mirror${WHITE} | ${GREEN}${speed} KB/s${NC}"

        if (( $(echo "$speed > $best_speed" | bc -l 2>/dev/null || echo "0") )); then
            best_speed=$speed
            best_mirror=$mirror
        fi
    done

    # Set the fastest mirror as the default
    if [ -n "$best_mirror" ]; then
        echo -e "${BLUE}--------------------------------------------${NC}"
        echo -e "${GREEN}Fastest mirror found:${NC}"
        echo -e "${CYAN}$best_mirror${WHITE} with speed ${GREEN}$best_speed KB/s${NC}"
        echo -e "${BLUE}--------------------------------------------${NC}"

        # Backup current sources
        if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
            sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.backup
            sudo sed -i "s|https\?://[^ ]*|$best_mirror|g" /etc/apt/sources.list.d/ubuntu.sources
        else
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
            sudo sed -i "s|https\?://[^ ]*|$best_mirror|g" /etc/apt/sources.list
        fi

        echo -e "${GREEN}✓ Mirror configuration updated${NC}"
        echo -e "${YELLOW}Updating package list...${NC}"
        sudo apt-get update
    else
        echo -e "${RED}No suitable mirror found.${NC}"
    fi
}

# Function to optimize DNS
optimize_dns() {
    echo -e "\n${BLUE}=== Optimizing DNS Settings ===${NC}\n"
    
    # DNS servers list
    SERVERS="217.218.155.155 185.20.163.4 78.157.42.101 31.24.234.37 2.189.44.44 185.20.163.2 194.60.210.66 217.218.127.127 2.188.21.130 31.24.200.4 2.185.239.138 5.145.112.39 85.185.85.6 217.219.132.88 178.22.122.100 194.36.174.1 185.53.143.3 80.191.209.105 78.157.42.100 213.176.123.5 185.55.226.26 185.161.112.38 194.225.152.10 2.188.21.131 2.188.21.132 10.202.10.10 46.224.1.42 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112"

    TEST_DOMAIN="google.com"
    OK_SERVERS=()
    MAX_OK=5

    # Backup existing resolv.conf
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null

    # Clear existing resolv.conf
    echo -n | sudo tee /etc/resolv.conf > /dev/null

    # Test DNS servers
    for DNS in $SERVERS; do
        if dig @"$DNS" "$TEST_DOMAIN" +time=1 +short > /dev/null 2>&1; then
            echo -e "${GREEN}[OK]${NC} $DNS"
            OK_SERVERS+=("$DNS")
        else
            echo -e "${RED}[FAIL]${NC} $DNS"
        fi

        # Stop after finding enough working servers
        if [ "${#OK_SERVERS[@]}" -ge "$MAX_OK" ]; then
            break
        fi
    done

    # Write working DNS servers to resolv.conf
    for DNS in "${OK_SERVERS[@]}"; do
        echo "nameserver $DNS" | sudo tee -a /etc/resolv.conf > /dev/null
    done

    echo -e "\n${GREEN}✅ Updated /etc/resolv.conf with ${#OK_SERVERS[@]} working nameservers.${NC}"
}

# Main menu
show_menu() {
    clear
    show_banner
    echo -e "${WHITE}Please select an option:${NC}"
    echo -e "${CYAN}1)${NC} Optimize Ubuntu Mirrors Only"
    echo -e "${CYAN}2)${NC} Optimize DNS Only"
    echo -e "${CYAN}3)${NC} Optimize Both (Mirrors + DNS)"
    echo -e "${CYAN}4)${NC} Exit"
    echo -e "${BLUE}--------------------------------------------${NC}"
    echo -n -e "${WHITE}Enter your choice [1-4]: ${NC}"
}

# Check for required commands
check_dependencies() {
    local missing=()
    
    if ! command -v wget &> /dev/null; then
        missing+=("wget")
    fi
    
    if ! command -v dig &> /dev/null; then
        missing+=("dnsutils")
    fi
    
    if ! command -v bc &> /dev/null; then
        missing+=("bc")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}Installing missing dependencies: ${missing[*]}${NC}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
}

# Main execution
main() {
    # Check if running with sudo/root
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run with sudo: sudo $0${NC}"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Handle command line arguments
    if [ $# -gt 0 ]; then
        case $1 in
            --mirrors)
                optimize_mirrors
                ;;
            --dns)
                optimize_dns
                ;;
            --both)
                optimize_mirrors
                optimize_dns
                ;;
            --help)
                echo -e "Usage: $0 [OPTION]"
                echo -e "  --mirrors    Optimize Ubuntu mirrors only"
                echo -e "  --dns        Optimize DNS only"
                echo -e "  --both       Optimize both mirrors and DNS"
                echo -e "  --help       Show this help message"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Use --help for usage.${NC}"
                exit 1
                ;;
        esac
    else
        # Interactive mode
        while true; do
            show_menu
            read choice
            
            case $choice in
                1)
                    optimize_mirrors
                    echo -e "\n${GREEN}Optimization complete!${NC}"
                    break
                    ;;
                2)
                    optimize_dns
                    echo -e "\n${GREEN}Optimization complete!${NC}"
                    break
                    ;;
                3)
                    optimize_mirrors
                    optimize_dns
                    echo -e "\n${GREEN}Both optimizations complete!${NC}"
                    break
                    ;;
                4)
                    echo -e "${GREEN}Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please try again.${NC}"
                    sleep 2
                    ;;
            esac
        done
    fi
}

# Run main function with all arguments
main "$@"
