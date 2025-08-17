#!/bin/bash

# FRP Management Script
# Manages FRP client and server instances based on config files in /root/frp/client and /root/frp/server, EFRP service, and provides FRP installation

# Define color codes for a modern look
BLUE='\033[0;34m'    # Regular Blue for logs
GREEN='\033[0;32m'   # Regular Green for start messages
RED='\033[0;31m'     # Regular Red for stop messages
YELLOW='\033[1;33m'  # Bright Yellow for highlights
CYAN='\033[1;36m'
BB='\033[1;34m'
NC='\033[0m'         # No Color

# Directories containing FRP client and server configuration files
CLIENT_CONFIG_DIR="/root/frp/client"
SERVER_CONFIG_DIR="/root/frp/server"

# Helper functions for installation
print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}       FRP Install Tool       ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[+] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# Cron for Garbage Collection / doesnt terminate process just triggers Garbage Collection and Ensuring BBR and FQ are Enabled 
optimize() {
    local -r cron_job="0 */3 * * * pkill -10 -x frpc; pkill -10 -x frps"
    local -r sysctl_conf="/etc/sysctl.conf"
    local -r bbr_module="/etc/modules-load.d/bbr.conf"
    
    # Ensure cron job exists (idempotent)
    sudo crontab -l 2>/dev/null | grep -Fq "${cron_job}" || {
        (sudo crontab -l 2>/dev/null; echo "${cron_job}") | sudo crontab -
    }
    
    # Configure BBR if not already optimal
    [[ "$(sysctl -n net.core.default_qdisc)" == "fq" && 
       "$(sysctl -n net.ipv4.tcp_congestion_control)" == "bbr" ]] && return
    
    # Apply BBR configuration atomically
    {
        echo "net.core.default_qdisc=fq"
        echo "net.ipv4.tcp_congestion_control=bbr"
    } | sudo tee -a "${sysctl_conf}" >/dev/null
    
    echo "tcp_bbr" | sudo tee "${bbr_module}" >/dev/null
    
    sudo modprobe tcp_bbr 2>/dev/null || true
    sudo sysctl -p >/dev/null
}

# Install FRP
install_frp() {
    print_info "Starting FRP installation..."
    
    # Detect platform
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l|armv6l) arch="arm" ;;
        *) print_error "Unsupported arch: $arch"; exit 1 ;;
    esac

    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    platform="${os}_${arch}"

    # Get latest version
    print_info "Fetching latest FRP version..."
    version=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep tag_name | cut -d '"' -f4 | sed 's/v//')
    url="https://github.com/fatedier/frp/releases/download/v${version}/frp_${version}_${platform}.tar.gz"

    print_info "Downloading $url"
    curl -L "$url" -o "/tmp/frp.tar.gz"

    print_info "Extracting..."
    tar -xzf /tmp/frp.tar.gz -C /tmp

    print_info "Installing frpc and frps..."
    cp /tmp/frp_${version}_${platform}/frpc /usr/local/bin/
    cp /tmp/frp_${version}_${platform}/frps /usr/local/bin/
    chmod +x /usr/local/bin/frpc /usr/local/bin/frps

    print_info "Creating config folders..."
    mkdir -p /root/frp/server
    mkdir -p /root/frp/client

    print_info "Writing frps@.service..."
    cat > /etc/systemd/system/frps@.service <<EOF
[Unit]
Description=FRP Server Service (%i)
Documentation=https://gofrp.org/en/docs/overview/
After=network.target nss-lookup.target network-online.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
ExecStart=/usr/local/bin/frps -c /root/frp/server/%i.toml
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    print_info "Writing frpc@.service..."
    cat > /etc/systemd/system/frpc@.service <<EOF
[Unit]
Description=FRP Client Service (%i)
Documentation=https://gofrp.org/en/docs/overview/
After=network.target nss-lookup.target network-online.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
ExecStart=/usr/local/bin/frpc -c /root/frp/client/%i.toml
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    print_info "Reloading systemd..."
    systemctl daemon-reload

    print_success "FRP $version installed and services created."
}

# Setup FRP Server
setup_server() {
    print_info "FRP Server Setup"

    read -p "Enter bindPort [7000]: " bindPort
    bindPort=${bindPort:-7000}

    echo "Enable Quic or KCP ? (default = 2):"
    echo "  1) none"
    echo "  2) quic"
    echo "  3) kcp"
    read -p "Protocol [2]: " proto_choice
    proto_choice=${proto_choice:-2}

    read -p "Enable TCP Mux (y/n) [n]: " use_mux
    use_mux=${use_mux:-n}

    read -p "Enter auth token [mikeesierrah]: " token
    token=${token:-mikeesierrah}

    mkdir -p /root/frp/server/
    config="/root/frp/server/server-$bindPort.toml"

    print_info "Writing config to $config"

    {
        echo "# Auto-generated frps config"
        echo 'bindAddr = "::"'
        echo "bindPort = $bindPort"

        if [[ $proto_choice == 2 ]]; then
            echo "quicBindPort = $bindPort"
        elif [[ $proto_choice == 3 ]]; then
            echo "kcpBindPort = $bindPort"
        fi
        echo

        if [[ $proto_choice == 2 ]]; then
            echo "transport.quic.keepalivePeriod = 10"
            echo "transport.quic.maxIdleTimeout = 30"
            echo "transport.quic.maxIncomingStreams = 100000"
        else
            echo "# transport.quic.keepalivePeriod = 10"
            echo "# transport.quic.maxIdleTimeout = 30"
            echo "# transport.quic.maxIncomingStreams = 100000"
        fi
        echo

        echo "transport.heartbeatTimeout = 90"
        echo "transport.maxPoolCount = 65535"
        echo "transport.tcpMux = $( [[ $use_mux =~ ^[Yy]$ ]] && echo true || echo false )"
        echo "transport.tcpMuxKeepaliveInterval = 10"
        echo "transport.tcpKeepalive = 120"
        echo
        echo 'auth.method = "token"'
        echo "auth.token = \"$token\""
    } > "$config"

    print_info "Enabling and starting frps@server-$bindPort..."
    systemctl enable --now frps@server-$bindPort

    print_success "Server setup complete."
}

# Setup FRP Client
setup_client() {
    print_info "FRP Client Setup"

    read -p "Server IP (v4 or v6): " server_ip

    read -p "Server port [7000]: " server_port
    server_port=${server_port:-7000}

    read -p "Auth token [mikeesierrah]: " auth_token
    auth_token=${auth_token:-mikeesierrah}

    echo "Choose transport protocol:"
    echo "1) tcp"
    echo "2) websocket"
    echo "3) quic"
    echo "4) kcp"
    read -p "Option [1]: " transport_option
    case $transport_option in
        2) transport="websocket" ;;
        3) transport="quic" ;;
        4) transport="kcp" ;;
        1|"") transport="tcp" ;;
        *) transport="tcp" ;;
    esac

    read -p "Enable TCP Mux? [y/N]: " use_mux
    [[ "$use_mux" =~ ^[Yy]$ ]] && mux="true" || mux="false"

    read -p "Local ports to expose (e.g. 22,6000-6006,6007): " port_input

    config_name="client-$server_port.toml"
    mkdir -p /root/frp/client/

    cat > "/root/frp/client/$config_name" <<EOF
serverAddr = "$server_ip"
serverPort = $server_port

loginFailExit = false

auth.method = "token"
auth.token = "$auth_token"

transport.protocol = "$transport"
transport.tcpMux = $mux
transport.tcpMuxKeepaliveInterval = 10
transport.dialServerTimeout = 10
transport.dialServerKeepalive = 120
transport.poolCount = 20
transport.heartbeatInterval = 30
transport.heartbeatTimeout = 90
transport.tls.enable = false
transport.quic.keepalivePeriod = 10
transport.quic.maxIdleTimeout = 30
transport.quic.maxIncomingStreams = 100000

{{- range \$_, \$v := parseNumberRangePair "$port_input" "$port_input" }}
[[proxies]]
name = "tcp-{{ \$v.First }}"
type = "tcp"
localIP = "127.0.0.1"
localPort = {{ \$v.First }}
remotePort = {{ \$v.Second }}
transport.useEncryption = false
transport.useCompression = true
{{- end }}
EOF

    service_name="${config_name%.toml}"
    systemctl enable --now "frpc@$service_name"
    
    print_success "Client setup complete."
}

# Advanced config management
advanced_config() {
    print_info "Advanced Configuration Management"
    echo
    echo "1) Server Configuration"
    echo "2) Client Configuration"
    echo "3) Back to main menu"
    echo
    read -p "Choose option [1-3]: " config_choice

    case $config_choice in
        1)
            if [[ ! -d "/root/frp/server" ]] || [[ -z "$(ls -A /root/frp/server/ 2>/dev/null)" ]]; then
                print_warning "No server configurations found in /root/frp/server/"
                return
            fi
            
            print_info "Available server configurations:"
            echo
            configs=($(ls /root/frp/server/*.toml 2>/dev/null | xargs -n1 basename))
            for i in "${!configs[@]}"; do
                echo "$((i+1))) ${configs[$i]}"
            done
            echo "$((${#configs[@]}+1))) Back"
            echo
            
            read -p "Select configuration to edit [1-$((${#configs[@]}+1))]: " server_choice
            
            if [[ $server_choice -eq $((${#configs[@]}+1)) ]]; then
                return
            elif [[ $server_choice -ge 1 && $server_choice -le ${#configs[@]} ]]; then
                selected_config="${configs[$((server_choice-1))]}"
                config_path="/root/frp/server/$selected_config"
                
                print_info "Current configuration ($selected_config):"
                echo "----------------------------------------"
                cat "$config_path"
                echo "----------------------------------------"
                echo
                
                read -p "Edit this file? (y/n) [n]: " edit_choice
                if [[ "$edit_choice" =~ ^[Yy]$ ]]; then
                    ${EDITOR:-nano} "$config_path"
                    
                    # Restart service if it's running
                    service_name="${selected_config%.toml}"
                    if systemctl is-active --quiet "frps@$service_name"; then
                        print_info "Restarting service frps@$service_name..."
                        systemctl restart "frps@$service_name"
                        print_success "Service restarted."
                    fi
                fi
            fi
            ;;
        2)
            if [[ ! -d "/root/frp/client" ]] || [[ -z "$(ls -A /root/frp/client/ 2>/dev/null)" ]]; then
                print_warning "No client configurations found in /root/frp/client/"
                return
            fi
            
            print_info "Available client configurations:"
            echo
            configs=($(ls /root/frp/client/*.toml 2>/dev/null | xargs -n1 basename))
            for i in "${!configs[@]}"; do
                echo "$((i+1))) ${configs[$i]}"
            done
            echo "$((${#configs[@]}+1))) Back"
            echo
            
            read -p "Select configuration to edit [1-$((${#configs[@]}+1))]: " client_choice
            
            if [[ $client_choice -eq $((${#configs[@]}+1)) ]]; then
                return
            elif [[ $client_choice -ge 1 && $client_choice -le ${#configs[@]} ]]; then
                selected_config="${configs[$((client_choice-1))]}"
                config_path="/root/frp/client/$selected_config"
                
                print_info "Current configuration ($selected_config):"
                echo "----------------------------------------"
                cat "$config_path"
                echo "----------------------------------------"
                echo
                
                read -p "Edit this file? (y/n) [n]: " edit_choice
                if [[ "$edit_choice" =~ ^[Yy]$ ]]; then
                    ${EDITOR:-nano} "$config_path"
                    
                    # Restart service if it's running
                    service_name="${selected_config%.toml}"
                    if systemctl is-active --quiet "frpc@$service_name"; then
                        print_info "Restarting service frpc@$service_name..."
                        systemctl restart "frpc@$service_name"
                        print_success "Service restarted."
                    fi
                fi
            fi
            ;;
        3)
            return
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
}

# Stop services
stop_services() {
    print_info "Stopping FRP services..."
    
    # Stop all running frps services
    running_servers=$(systemctl list-units --type=service --state=running | grep "frps@" | awk '{print $1}' || true)
    if [[ -n "$running_servers" ]]; then
        print_info "Stopping server services..."
        for service in $running_servers; do
            print_info "Stopping $service..."
            systemctl stop "$service"
        done
    fi
    
    # Stop all running frpc services
    running_clients=$(systemctl list-units --type=service --state=running | grep "frpc@" | awk '{print $1}' || true)
    if [[ -n "$running_clients" ]]; then
        print_info "Stopping client services..."
        for service in $running_clients; do
            print_info "Stopping $service..."
            systemctl stop "$service"
        done
    fi
    
    print_success "All FRP services stopped."
}

# Remove FRP completely
remove_frp() {
    print_warning "This will completely remove FRP and all configurations!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Removal cancelled."
        return
    fi
    
    print_info "Stopping all FRP services..."
    stop_services
    
    print_info "Disabling and removing services..."
    # Disable and remove all frp services
    enabled_servers=$(systemctl list-unit-files | grep "frps@" | awk '{print $1}' || true)
    for service in $enabled_servers; do
        systemctl disable "$service" 2>/dev/null || true
    done
    
    enabled_clients=$(systemctl list-unit-files | grep "frpc@" | awk '{print $1}' || true)
    for service in $enabled_clients; do
        systemctl disable "$service" 2>/dev/null || true
    done
    
    print_info "Removing service files..."
    rm -f /etc/systemd/system/frps@.service
    rm -f /etc/systemd/system/frpc@.service
    
    print_info "Removing binaries..."
    rm -f /usr/local/bin/frpc
    rm -f /usr/local/bin/frps
    
    print_info "Removing configuration directories..."
    rm -rf /root/frp/
    
    print_info "Reloading systemd..."
    systemctl daemon-reload
    
    print_success "FRP completely removed from system."
}

# Show service status
show_status() {
    print_info "FRP Service Status"
    echo
    
    # Check if binaries exist
    if [[ ! -f "/usr/local/bin/frpc" ]] || [[ ! -f "/usr/local/bin/frps" ]]; then
        print_warning "FRP is not installed."
        return
    fi
    
    print_info "Installed FRP version:"
    /usr/local/bin/frps --version 2>/dev/null || echo "Unable to determine version"
    echo
    
    print_info "Running services:"
    systemctl list-units --type=service --state=running | grep -E "frp[sc]@" || echo "No FRP services running"
    echo
    
    print_info "Enabled services:"
    systemctl list-unit-files | grep -E "frp[sc]@.*enabled" || echo "No FRP services enabled"
    echo
    
    print_info "Configuration files:"
    echo "Server configs:"
    ls -la /root/frp/server/ 2>/dev/null || echo "  No server configs found"
    echo "Client configs:"
    ls -la /root/frp/client/ 2>/dev/null || echo "  No client configs found"
}

# Installation main menu
install_menu() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        return 1
    fi

    # Ensure optimization
    optimize

    while true; do
        clear
        print_header
        
        echo "1) Install FRP"
        echo "2) Setup FRP Server"
        echo "3) Setup FRP Client"
        echo "4) Advanced Configuration"
        echo "5) Show Status"
        echo "6) Stop All Services"
        echo "7) Remove FRP"
        echo "8) Back to main menu"
        echo
        
        read -p "Choose an option [1-8]: " choice
        echo
        
        case $choice in
            1)
                install_frp
                read -p "Press Enter to continue..."
                ;;
            2)
                setup_server
                read -p "Press Enter to continue..."
                ;;
            3)
                setup_client
                read -p "Press Enter to continue..."
                ;;
            4)
                advanced_config
                read -p "Press Enter to continue..."
                ;;
            5)
                show_status
                read -p "Press Enter to continue..."
                ;;
            6)
                stop_services
                read -p "Press Enter to continue..."
                ;;
            7)
                remove_frp
                read -p "Press Enter to continue..."
                ;;
            8)
                return
                ;;
            *)
                print_error "Invalid option. Please choose 1-8."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to check FRP client logs
logs_frpc() {
    local lines
    echo -e "${BLUE}Enter number of log lines to display (default 3, e.g., 200 for extended):${NC} \c"
    read lines
    lines=${lines:-3} # Default to 3 if empty
    if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input, using default of 3 lines.${NC}"
        lines=3
    fi
    echo -e "${BLUE}Checking FRP client logs (last $lines lines)...${NC}"
    if [ ! -d "$CLIENT_CONFIG_DIR" ]; then
        echo -e "${RED}Client configuration directory $CLIENT_CONFIG_DIR not found!${NC}"
        return 1
    fi
    for config_file in "$CLIENT_CONFIG_DIR"/*.toml; do
        if [ ! -e "$config_file" ]; then
            echo -e "${RED}No client configuration files found in $CLIENT_CONFIG_DIR${NC}"
            return 1
        fi
        client_name=$(basename "$config_file" .toml)
        echo -e "${YELLOW}Logs for frpc@$client_name:${NC}"
        journalctl -u frpc@"$client_name" -n "$lines" --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to check FRP server logs
logs_frps() {
    local lines
    echo -e "${BLUE}Enter number of log lines to display (default 3, e.g., 200 for extended):${NC} \c"
    read lines
    lines=${lines:-3} # Default to 3 if empty
    if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input, using default of 3 lines.${NC}"
        lines=3
    fi
    echo -e "${BLUE}Checking FRP server logs (last $lines lines)...${NC}"
    if [ ! -d "$SERVER_CONFIG_DIR" ]; then
        echo -e "${RED}Server configuration directory $SERVER_CONFIG_DIR not found!${NC}"
        return 1
    fi
    for config_file in "$SERVER_CONFIG_DIR"/*.toml; do
        if [ ! -e "$config_file" ]; then
            echo -e "${RED}No server configuration files found in $SERVER_CONFIG_DIR${NC}"
            return 1
        fi
        server_name=$(basename "$config_file" .toml)
        echo -e "${YELLOW}Logs for frps@$server_name:${NC}"
        journalctl -u frps@"$server_name" -n "$lines" --no-pager | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
        echo ""
    done
}

# Function to check EFRP logs
logs_efrp() {
    echo -e "${BLUE}Showing EFRP service logs (follow mode, press Ctrl+C to stop)...${NC}"
    journalctl -u EFRP.service -e -f | sed -E 's/^[A-Za-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^ ]* //'
    echo ""
}

# Function to start FRP clients
start_frpc() {
    echo -e "${GREEN}Starting FRP clients...${NC}"
    if [ ! -d "$CLIENT_CONFIG_DIR" ]; then
        echo -e "${RED}Client configuration directory $CLIENT_CONFIG_DIR not found!${NC}"
        return 1
    fi
    for config_file in "$CLIENT_CONFIG_DIR"/*.toml; do
        if [ ! -e "$config_file" ]; then
            echo -e "${RED}No client configuration files found in $CLIENT_CONFIG_DIR${NC}"
            return 1
        fi
        client_name=$(basename "$config_file" .toml)
        if systemctl start frpc@"$client_name"; then
            echo -e "${GREEN}Started frpc@$client_name${NC}"
        else
            echo -e "${RED}Failed to start frpc@$client_name${NC}"
        fi
        systemctl status frpc@"$client_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to stop FRP clients
stop_frpc() {
    echo -e "${RED}Stopping FRP clients...${NC}"
    if [ ! -d "$CLIENT_CONFIG_DIR" ]; then
        echo -e "${RED}Client configuration directory $CLIENT_CONFIG_DIR not found!${NC}"
        return 1
    fi
    for config_file in "$CLIENT_CONFIG_DIR"/*.toml; do
        if [ ! -e "$config_file" ]; then
            echo -e "${RED}No client configuration files found in $CLIENT_CONFIG_DIR${NC}"
            return 1
        fi
        client_name=$(basename "$config_file" .toml)
        if systemctl stop frpc@"$client_name"; then
            echo -e "${RED}Stopped frpc@$client_name${NC}"
        else
            echo -e "${RED}Failed to stop frpc@$client_name${NC}"
        fi
        systemctl status frpc@"$client_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to restart FRP clients
restart_frpc() {
    echo -e "${BLUE}Restart FRP clients:${NC}"
    echo -e "${YELLOW}  [1] Restart all clients${NC}"
    echo -e "${YELLOW}  [2] Restart a specific client${NC}"
    echo -e "${RED}  [3] Cancel${NC}"
    echo -e "${BLUE}Enter your choice (1-3):${NC} \c"
    read choice
    case $choice in
        1)
            echo -e "${GREEN}Restarting all FRP clients...${NC}"
            if [ ! -d "$CLIENT_CONFIG_DIR" ]; then
                echo -e "${RED}Client configuration directory $CLIENT_CONFIG_DIR not found!${NC}"
                return 1
            fi
            for config_file in "$CLIENT_CONFIG_DIR"/*.toml; do
                if [ ! -e "$config_file" ]; then
                    echo -e "${RED}No client configuration files found in $CLIENT_CONFIG_DIR${NC}"
                    return 1
                fi
                client_name=$(basename "$config_file" .toml)
                if systemctl restart frpc@"$client_name"; then
                    echo -e "${GREEN}Restarted frpc@$client_name${NC}"
                else
                    echo -e "${RED}Failed to restart frpc@$client_name${NC}"
                fi
                systemctl status frpc@"$client_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
                echo ""
            done
            ;;
        2)
            echo -e "${BLUE}Available clients:${NC}"
            if [ ! -d "$CLIENT_CONFIG_DIR" ]; then
                echo -e "${RED}Client configuration directory $CLIENT_CONFIG_DIR not found!${NC}"
                return 1
            fi
            mapfile -t config_files < <(ls "$CLIENT_CONFIG_DIR"/*.toml 2>/dev/null)
            if [ ${#config_files[@]} -eq 0 ]; then
                echo -e "${RED}No client configuration files found in $CLIENT_CONFIG_DIR${NC}"
                return 1
            fi
            for i in "${!config_files[@]}"; do
                client_name=$(basename "${config_files[$i]}" .toml)
                echo -e "${YELLOW}  [$((i+1))] $client_name${NC}"
            done
            echo -e "${BLUE}Enter the number of the client to restart:${NC} \c"
            read client_choice
            if ! [[ "$client_choice" =~ ^[0-9]+$ ]] || [ "$client_choice" -lt 1 ] || [ "$client_choice" -gt ${#config_files[@]} ]; then
                echo -e "${RED}Invalid selection, cancelling restart.${NC}"
                return 1
            fi
            client_name=$(basename "${config_files[$((client_choice-1))]}" .toml)
            echo -e "${GREEN}Restarting frpc@$client_name...${NC}"
            if systemctl restart frpc@"$client_name"; then
                echo -e "${GREEN}Restarted frpc@$client_name${NC}"
            else
                echo -e "${RED}Failed to restart frpc@$client_name${NC}"
            fi
            systemctl status frpc@"$client_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
            echo ""
            ;;
        3)
            echo -e "${RED}Restart cancelled.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option, cancelling restart.${NC}"
            ;;
    esac
}

# Function to start FRP servers
start_frps() {
    echo -e "${GREEN}Starting FRP servers...${NC}"
    if [ ! -d "$SERVER_CONFIG_DIR" ]; then
        echo -e "${RED}Server configuration directory $SERVER_CONFIG_DIR not found!${NC}"
        return 1
    fi
    for config_file in "$SERVER_CONFIG_DIR"/*.toml; do
        if [ ! -e "$config_file" ]; then
            echo -e "${RED}No server configuration files found in $SERVER_CONFIG_DIR${NC}"
            return 1
        fi
        server_name=$(basename "$config_file" .toml)
        if systemctl start frps@"$server_name"; then
            echo -e "${GREEN}Started frps@$server_name${NC}"
        else
            echo -e "${RED}Failed to start frps@$server_name${NC}"
        fi
        systemctl status frps@"$server_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to stop FRP servers
stop_frps() {
    echo -e "${RED}Stopping FRP servers...${NC}"
    if [ ! -d "$SERVER_CONFIG_DIR" ]; then
        echo -e "${RED}Server configuration directory $SERVER_CONFIG_DIR not found!${NC}"
        return 1
    fi
    for config_file in "$SERVER_CONFIG_DIR"/*.toml; do
        if [ ! -e "$config_file" ]; then
            echo -e "${RED}No server configuration files found in $SERVER_CONFIG_DIR${NC}"
            return 1
        fi
        server_name=$(basename "$config_file" .toml)
        if systemctl stop frps@"$server_name"; then
            echo -e "${RED}Stopped frps@$server_name${NC}"
        else
            echo -e "${RED}Failed to stop frps@$server_name${NC}"
        fi
        systemctl status frps@"$server_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
        echo ""
    done
}

# Function to restart FRP servers
restart_frps() {
    echo -e "${BLUE}Restart FRP servers:${NC}"
    echo -e "${YELLOW}  [1] Restart all servers${NC}"
    echo -e "${YELLOW}  [2] Restart a specific server${NC}"
    echo -e "${RED}  [3] Cancel${NC}"
    echo -e "${BLUE}Enter your choice (1-3):${NC} \c"
    read choice
    case $choice in
        1)
            echo -e "${GREEN}Restarting all FRP servers...${NC}"
            if [ ! -d "$SERVER_CONFIG_DIR" ]; then
                echo -e "${RED}Server configuration directory $SERVER_CONFIG_DIR not found!${NC}"
                return 1
            fi
            for config_file in "$SERVER_CONFIG_DIR"/*.toml; do
                if [ ! -e "$config_file" ]; then
                    echo -e "${RED}No server configuration files found in $SERVER_CONFIG_DIR${NC}"
                    return 1
                fi
                server_name=$(basename "$config_file" .toml)
                if systemctl restart frps@"$server_name"; then
                    echo -e "${GREEN}Restarted frps@$server_name${NC}"
                else
                    echo -e "${RED}Failed to restart frps@$server_name${NC}"
                fi
                systemctl status frps@"$server_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
                echo ""
            done
            ;;
        2)
            echo -e "${BLUE}Available servers:${NC}"
            if [ ! -d "$SERVER_CONFIG_DIR" ]; then
                echo -e "${RED}Server configuration directory $SERVER_CONFIG_DIR not found!${NC}"
                return 1
            fi
            mapfile -t config_files < <(ls "$SERVER_CONFIG_DIR"/*.toml 2>/dev/null)
            if [ ${#config_files[@]} -eq 0 ]; then
                echo -e "${RED}No server configuration files found in $SERVER_CONFIG_DIR${NC}"
                return 1
            fi
            for i in "${!config_files[@]}"; do
                server_name=$(basename "${config_files[$i]}" .toml)
                echo -e "${YELLOW}  [$((i+1))] $server_name${NC}"
            done
            echo -e "${BLUE}Enter the number of the server to restart:${NC} \c"
            read server_choice
            if ! [[ "$server_choice" =~ ^[0-9]+$ ]] || [ "$server_choice" -lt 1 ] || [ "$server_choice" -gt ${#config_files[@]} ]; then
                echo -e "${RED}Invalid selection, cancelling restart.${NC}"
                return 1
            fi
            server_name=$(basename "${config_files[$((server_choice-1))]}" .toml)
            echo -e "${GREEN}Restarting frps@$server_name...${NC}"
            if systemctl restart frps@"$server_name"; then
                echo -e "${GREEN}Restarted frps@$server_name${NC}"
            else
                echo -e "${RED}Failed to restart frps@$server_name${NC}"
            fi
            systemctl status frps@"$server_name" --no-pager | grep "Active:" | sed 's/.*Active:/    Active:/'
            echo ""
            ;;
        3)
            echo -e "${RED}Restart cancelled.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option, cancelling restart.${NC}"
            ;;
    esac
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

# Function to display client submenu
client_menu() {
    while true; do
        clear
        echo -e "${BLUE}┌──────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│          FRP Client Management                   │${NC}"
        echo -e "${BLUE}└──────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${GREEN}Client Options:${NC}"
        echo -e "${GREEN}  [1] Start clients${NC}"
        echo -e "${RED}  [2] Stop clients${NC}"
        echo -e "${YELLOW}  [3] Check client logs${NC}"
        echo -e "${GREEN}  [4] Restart clients${NC}"
        echo -e "${RED}  [5] Back to main menu${NC}"
        echo ""
        echo -e "${BLUE}──────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}Enter your choice (1-5):${NC} \c"
        read choice
        case $choice in
            1) start_frpc ;;
            2) stop_frpc ;;
            3) logs_frpc ;;
            4) restart_frpc ;;
            5) return ;;
            *) echo -e "${RED}Invalid option, please select 1-5${NC}" ;;
        esac
        echo ""
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -s
    done
}

# Function to display server submenu
server_menu() {
    while true; do
        clear
        echo -e "${BLUE}┌──────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│          FRP Server Management                   │${NC}"
        echo -e "${BLUE}└──────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${GREEN}Server Options:${NC}"
        echo -e "${GREEN}  [1] Start servers${NC}"
        echo -e "${RED}  [2] Stop servers${NC}"
        echo -e "${YELLOW}  [3] Check server logs${NC}"
        echo -e "${GREEN}  [4] Restart servers${NC}"
        echo -e "${RED}  [5] Back to main menu${NC}"
        echo ""
        echo -e "${BLUE}──────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}Enter your choice (1-5):${NC} \c"
        read choice
        case $choice in
            1) start_frps ;;
            2) stop_frps ;;
            3) logs_frps ;;
            4) restart_frps ;;
            5) return ;;
            *) echo -e "${RED}Invalid option, please select 1-5${NC}" ;;
        esac
        echo ""
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -s
    done
}

# Function to display EFRP submenu
efrp_menu() {
    while true; do
        clear
        echo -e "${BLUE}┌──────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}│          EFRP Service Management                 │${NC}"
        echo -e "${BLUE}└──────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${GREEN}EFRP Options:${NC}"
        echo -e "${GREEN}  [1] Start EFRP service${NC}"
        echo -e "${RED}  [2] Stop EFRP service${NC}"
        echo -e "${YELLOW}  [3] Check EFRP logs${NC}"
        echo -e "${RED}  [4] Back to main menu${NC}"
        echo ""
        echo -e "${BLUE}──────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}Enter your choice (1-4):${NC} \c"
        read choice
        case $choice in
            1) start_efrp ;;
            2) stop_efrp ;;
            3) logs_efrp ;;
            4) return ;;
            *) echo -e "${RED}Invalid option, please select 1-4${NC}" ;;
        esac
        echo ""
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read -s
    done
}

# Main menu
while true; do
    clear
    echo -e " ${BB} .d88888b.          d8b                         888     888 8888888b.  888b    888 "
    echo -e " ${BB}d88P^ ^Y88b         Y8P                         888     888 888   Y88b 8888b   888 "
    echo -e " ${BB}888     888                                     888     888 888    888 88888b  888 "
    echo -e " ${BB}888     888 888d888 888  .d88b.  88888b.        Y88b   d88P 888   d88P 888Y88b 888 "
    echo -e " ${BB}888     888 888P^   888 d88^^88b 888 ^88b        Y88b d88P  8888888P^  888 Y88b888 "
    echo -e " ${BB}888     888 888     888 888  888 888  888         Y88o88P   888        888  Y88888 "
    echo -e " ${BB}Y88b. .d88P 888     888 Y88..88P 888  888          Y888P    888        888   Y8888 "
    echo -e " ${BB} ^Y88888P^  888     888  ^Y88P^  888  888           Y8P     888        888    Y888 "
    echo ""
    echo -e "${BLUE}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│          FRP Management Tool                     │${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${GREEN}Main Menu:${NC}"
    echo -e "${CYAN}  [1] Manage FRP clients${NC}"
    echo -e "${CYAN}  [2] Manage FRP servers${NC}"
    echo -e "${CYAN}  [3] Manage EFRP service${NC}"
    echo -e "${CYAN}  [4] Install FRP${NC}"
    echo -e "${RED}  [5] Exit${NC}"
    echo ""
    echo -e "${BLUE}──────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}Enter your choice (1-5):${NC} \c"
    read choice
    case $choice in
        1) client_menu ;;
        2) server_menu ;;
        3) efrp_menu ;;
        4) install_menu ;;
        5) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option, please select 1-5${NC}" ;;
    esac
    echo ""
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read -s
done
