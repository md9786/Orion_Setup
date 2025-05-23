#!/bin/bash
# Update the package list
echo "🟢 Updating package list..."
apt-get update -y && apt-get upgrade -y

# Function to display the main menu
show_menu() {
    clear
    echo " .d88888b.          d8b                         888     888 8888888b.  888b    888 "
    echo "d88P^ ^Y88b         Y8P                         888     888 888   Y88b 8888b   888 "
    echo "888     888                                     888     888 888    888 88888b  888 "
    echo "888     888 888d888 888  .d88b.  88888b.        Y88b   d88P 888   d88P 888Y88b 888 "
    echo "888     888 888P^   888 d88^^88b 888 ^88b        Y88b d88P  8888888P^  888 Y88b888 "
    echo "888     888 888     888 888  888 888  888         Y88o88P   888        888  Y88888 "
    echo "Y88b. .d88P 888     888 Y88..88P 888  888          Y888P    888        888   Y8888 "
    echo " ^Y88888P^  888     888  ^Y88P^  888  888           Y8P     888        888    Y888 "
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║           Server Setup Menu                ║"
    echo "╠════════════════════════════════════════════╣"
    echo "║ 1. Domestic Server Setup (Blue)            ║"
    echo "║ 2. Foreign Server Setup (Purple)           ║"
    echo "║ 3. Manual Domestic Setup                   ║"
    echo "║ 4. Manual Foreign Setup                    ║"
    echo "║ 0. Exit                                    ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    read -p "Enter your choice (0-4): " choice
}

# Function to display manual domestic components
show_domestic_components() {
    clear
    echo "╔════════════════════════════════════════════╗"
    echo "║       Manual Domestic Components           ║"
    echo "╠════════════════════════════════════════════╣"
    echo "║ 1. Basic Packages (vnstat, jq, bc, etc.)   ║"
    echo "║ 2. Certbot and SSL Certificates            ║"
    echo "║ 3. DNS Configuration                       ║"
    echo "║ 4. Configure Nginx,FakeuploadFiles,homepage║"
    echo "║ 5. Traffic Limiter                         ║"
    echo "║ 6. 3x-ui Panel                             ║"
    echo "║ 7. Upload Monitoring Script                ║"
    echo "║ 8. ALL Components                          ║"
    echo "║ 0. Back to Main Menu                       ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    read -p "Select components to install (comma-separated, e.g., 1,2,3): " components
}

# Function to display manual foreign components
show_foreign_components() {
    clear
    echo "╔════════════════════════════════════════════╗"
    echo "║       Manual Foreign Components            ║"
    echo "╠════════════════════════════════════════════╣"
    echo "║ 1. Basic Packages (vnstat, jq, bc, etc.)   ║"
    echo "║ 2. Certbot and SSL Certificates            ║"
    echo "║ 3. DNS Configuration                       ║"
    echo "║ 4. Swap Memory Configuration               ║"
    echo "║ 5. Warp Proxy                              ║"
    echo "║ 6. AdGuard Home install and configure      ║"
    echo "║ 7. 3x-ui Panel                             ║"
    echo "║ 8. ALL Components                          ║"
    echo "║ 0. Back to Main Menu                       ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    read -p "Select components to install (comma-separated, e.g., 1,2,3): " components
}

# Function to get 3x-ui credentials
get_xui_credentials() {
    echo "🟢 3x-ui Panel Configuration"
    read -p "Enter username for 3x-ui (default: dani): " XUI_USERNAME
    XUI_USERNAME=${XUI_USERNAME:-dani}
    
    while true; do
        read -s -p "Enter password for 3x-ui: " XUI_PASSWORD
        echo
        if [ -z "$XUI_PASSWORD" ]; then
            echo "🔴 Password cannot be empty. Please try again."
        else
            read -s -p "Confirm password: " XUI_PASSWORD_CONFIRM
            echo
            if [ "$XUI_PASSWORD" != "$XUI_PASSWORD_CONFIRM" ]; then
                echo "🔴 Passwords do not match. Please try again."
            else
                break
            fi
        fi
    done
}

# Function to get common inputs (domain and IP)
get_common_inputs() {
    # Get domain name
    while [ -z "$DOMAIN" ]; do
        read -p "Enter your domain name (e.g., example.com): " DOMAIN
        if [ -z "$DOMAIN" ]; then
            echo "🔴 Domain name cannot be empty. Please try again."
        fi
    done

    # Get IPv4 address
    while [ -z "$IPV4" ]; do
        read -p "Enter your DNS server IPv4 address (e.g., 1.1.1.1): " IPV4
        if [ -z "$IPV4" ]; then
            echo "🔴 IPv4 address cannot be empty. Please try again."
        fi
    done
}

# Function to detect network interfaces
detect_interfaces() {
    interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
    if [ ${#interfaces[@]} -eq 0 ]; then
        echo "🔴 No network interfaces found!"
        exit 1
    fi
    echo "${interfaces[@]}"
}

# Function to get network interface
get_network_interface() {
    echo "🟢 Detecting network interfaces..."
    interfaces=($(detect_interfaces))

    if [ ${#interfaces[@]} -eq 1 ]; then
        IFACE="${interfaces[0]}"
        echo "🟢 Only one interface found: $IFACE"
    else
        echo "🟢 Available network interfaces:"
        for i in "${!interfaces[@]}"; do
            echo "$((i+1)). ${interfaces[$i]}"
        done
        
        while true; do
            read -p "Select interface for traffic control (1-${#interfaces[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#interfaces[@]} ]; then
                IFACE="${interfaces[$((choice-1))]}"
                break
            else
                echo "🟢 Invalid selection. Please try again."
            fi
        done
    fi
}

# Function to get rate limit
get_rate_limit() {
    while true; do
        read -p "Enter rate limit in MB/s for ports 80/443 (e.g., 10 for 10MB/s): " MB_RATE
        if [[ "$MB_RATE" =~ ^[0-9]+$ ]]; then
            # Convert MB/s to mbit (1 byte = 8 bits)
            RATE="$((MB_RATE * 8))mbit"
            echo "🟢 Set rate limit: ${MB_RATE}MB/s (converted to ${RATE} for traffic control)"
            break
        else
            echo "🔴 Invalid input. Please enter a number (e.g., 10 for 10MB/s)."
        fi
    done
}

# Function to install basic packages
install_basic_packages() {
    echo "🟢 Installing basic packages..."
    sudo apt-get install -y vnstat jq bc nginx rar
    sudo systemctl enable vnstat
    sudo systemctl start vnstat
    sudo systemctl enable nginx
    sudo systemctl start nginx
}

# Function to install Certbot and SSL certificates
install_certbot() {
    echo "🟢 Installing Certbot and obtaining SSL certificates..."
    apt-get install certbot -y
    mkdir -p "/root/cert/$DOMAIN"
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$DOMAIN"
    certbot renew --dry-run
    ln -s "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "/root/cert/$DOMAIN/fullchain.pem"
    ln -s "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "/root/cert/$DOMAIN/privkey.pem"
}

# Function to configure DNS
configure_dns() {
    echo "🟢 Configuring DNS settings..."
    sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
    sudo bash -c "cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=$IPV4
EOF"
    sudo systemctl restart systemd-resolved
}

# Function to configure nginx with sample files
install_nginx() {
    echo "🟢 Configuring nginx with fake upload files..."
    cd /var/www/html
    TEMP_DIR=$(mktemp -d)
    dd if=/dev/urandom of=$TEMP_DIR/dummy_file bs=1M count=100
    rar a -m0 1.rar $TEMP_DIR/dummy_file
    for i in {2..10}; do
        cp 1.rar ${i}.rar
    done
    rm -rf $TEMP_DIR
echo "🟢 Configure default nginx page"
    # Configure default nginx page
    FILE_PATH="/var/www/html/index.nginx-debian.html"
      NEW_CONTENT='<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Image Upscaler</title>
    <style>
        body {
            font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #121212;
            color: #e0e0e0;
            background-position: 0 0, 30px 30px;
            background-size: 60px 60px;
        }

        .container {
            text-align: center;
            background: rgba(30, 30, 30, 0.9);
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.5);
        }

        h1 {
            margin-bottom: 20px;
        }

        h2 {
            margin-bottom: 20px;
            font-size: 13px;
        }

        input[type="file"] {
            display: block;
            margin: 20px auto;
        }

        #uploadBtn {
            margin-top: 10px;
            padding: 10px 20px;
            font-size: 16px;
            border: none;
            border-radius: 5px;
            background-color: #6200ea;
            color: white;
            cursor: pointer;
            transition: background-color 0.3s;
        }

        #uploadBtn:hover {
            background-color: #3700b3;
        }

        #message {
            margin-top: 20px;
            font-size: 18px;
        }

        #result {
            margin-top: 20px;
        }

        #downloadLink {
            text-decoration: none;
            color: #6200ea;
            font-weight: bold;
        }

        .loading-bar {
            width: 100%;
            background-color: #333;
            height: 5px;
            border-radius: 3px;
            margin-top: 20px;
            overflow: hidden;
            position: relative;
            display: none;
        }

        .loading-bar::before {
            content: "";
            position: absolute;
            width: 0;
            height: 100%;
            background-color: #6200ea;
            animation: loading 60s linear forwards;
        }

        @keyframes loading {
            from {
                width: 0;
            }
            to {
                width: 100%;
            }
        }

        #bg {
            position: fixed;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            z-index: -1;
        }
    </style>
</head>
<body>
    <div id="bg"></div>
    <div class="container">
        <h1>AI Image Upscaler</h1>
        <h2>!!!this is a demo for testing purposes only!!!</h2>
        <input type="file" id="upload" accept="image/*">
        <button id="uploadBtn">Upload Image</button>
        <div id="message"></div>
        <div class="loading-bar" id="loadingBar"></div>
        <div id="result" style="display: none;">
            <a id="downloadLink" href="#" download="upscaled-image.png">Download Upscaled Image</a>
        </div>
    </div>
    <script>
        document.getElementById("uploadBtn").addEventListener("click", () => {
            const uploadInput = document.getElementById("upload");
            const file = uploadInput.files[0];

            if (!file) {
                alert("Please upload an image.");
                return;
            }

            const reader = new FileReader();
            reader.onload = function (e) {
                const img = new Image();
                img.onload = function () {
                    const canvas = document.createElement("canvas");
                    const ctx = canvas.getContext("2d");
                    canvas.width = img.width * 2;
                    canvas.height = img.height * 2;
                    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

                    document.getElementById("message").textContent = "Processing image...";
                    document.getElementById("loadingBar").style.display = "block";

                    setTimeout(() => {
                        canvas.toBlob(blob => {
                            const url = URL.createObjectURL(blob);
                            const downloadLink = document.getElementById("downloadLink");
                            downloadLink.href = url;
                            document.getElementById("result").style.display = "block";
                            document.getElementById("message").textContent = "Image processed successfully!";
                            document.getElementById("loadingBar").style.display = "none";
                        }, "image/png");
                    }, 60000);
                };
                img.src = e.target.result;
            };
            reader.readAsDataURL(file);
        });
    </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r121/three.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/vanta@latest/dist/vanta.waves.min.js"></script>
    <script>
        VANTA.WAVES({
            el: "#bg",
            mouseControls: true,
            touchControls: true,
            gyroControls: false,
            minHeight: 200.00,
            minWidth: 200.00,
            scale: 1.00,
            scaleMobile: 1.00,
            color: 0x22043,
            shininess: 21.00,
            waveHeight: 24.00,
            waveSpeed: 0.80,
            zoom: 0.78
        });
    </script>
</body>
</html>'

    # Check if the file exists
    if [[ -f "$FILE_PATH" ]]; then
        # Replace the content of the file with the new content
        echo "$NEW_CONTENT" > "$FILE_PATH"
        echo "🟢 The content of $FILE_PATH has been replaced successfully."
    else
        echo "🔴 Error: $FILE_PATH does not exist."
        exit 1
    fi

}

# Function to install traffic limiter
install_traffic_limiter() {
    echo "🟢 Installing traffic limiter..."
    get_network_interface
    

    SERVICE_NAME="traffic-limiter"
    SCRIPT_PATH="/usr/local/bin/traffic_control.sh"
    COMMAND_PATH="/usr/local/bin/traffic-limiter"

    # Create the traffic control script
    sudo tee $SCRIPT_PATH > /dev/null <<EOF
#!/bin/bash

IFACE="$IFACE"
RATE="$RATE"
MB_RATE="$MB_RATE"
SERVICE_NAME="$SERVICE_NAME"

# Main menu
while true; do
    echo " "
    echo "🟢 Traffic Control Menu for \$IFACE"
    echo "🟢 1. Apply traffic limits (\${MB_RATE}MB/s) (and enable on boot)"
    echo "🟢 2. Remove traffic limits (and disable on boot)"
    echo "🟢 3. Check current traffic settings"
    echo "🔴 0. Exit"
    echo -n "Select option: "
    read choice
    
    case \$choice in
        1)
            echo "Applying traffic limits to \$IFACE..."
            echo "Rate limit: \${MB_RATE}MB/s (as \${RATE})"
            # Clear existing rules
            tc qdisc del dev \$IFACE root 2>/dev/null || true
            
            # Add root qdisc
            tc qdisc add dev \$IFACE root handle 1: htb default 30
            
            # Create class with rate limit
            tc class add dev \$IFACE parent 1: classid 1:1 htb rate \$RATE
            
            # Create filters for ports 80 and 443
            tc filter add dev \$IFACE protocol ip parent 1:0 prio 1 u32 match ip sport 80 0xffff flowid 1:1
            tc filter add dev \$IFACE protocol ip parent 1:0 prio 1 u32 match ip dport 80 0xffff flowid 1:1
            tc filter add dev \$IFACE protocol ip parent 1:0 prio 1 u32 match ip sport 443 0xffff flowid 1:1
            tc filter add dev \$IFACE protocol ip parent 1:0 prio 1 u32 match ip dport 443 0xffff flowid 1:1
            
            echo "Traffic limits applied:"
            tc qdisc show dev \$IFACE
            tc class show dev \$IFACE
            
            systemctl enable \$SERVICE_NAME
            echo "Traffic limits applied and will persist after reboot"
            ;;
        2)
            echo "Restoring default traffic settings on \$IFACE..."
            tc qdisc del dev \$IFACE root 2>/dev/null || true
            echo "Traffic limits removed"
            
            systemctl disable \$SERVICE_NAME
            echo "Traffic limits removed and will not be applied on reboot"
            ;;
        3)
            echo " "
            echo "🟢 Current qdisc:"
            tc qdisc show dev \$IFACE
            echo " "
            echo "🟢 Current classes:"
            tc class show dev \$IFACE
            echo " "
            echo "🟢 Current filters:"
            tc filter show dev \$IFACE
            ;;
        0)
            echo "Exiting traffic control"
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
EOF

    # Make the script executable
    sudo chmod +x $SCRIPT_PATH
    sudo ln -sf $SCRIPT_PATH $COMMAND_PATH

    # Create systemd service file
    sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Traffic Limiter Service
After=network.target

[Service]
Type=oneshot
ExecStart=$COMMAND_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    sudo systemctl daemon-reload
}

# Function to install upload monitor
install_upload_monitor() {
    echo "🟢 Installing upload monitor..."
    sudo tee /root/upload.sh >/dev/null <<'EOF'
#!/bin/bash

echo "🟢 Monitoring network traffic..."

# Get network traffic data
traffic=$(vnstat --json)

# Extract total received and transmitted bytes
upload=$(echo "$traffic" | jq -r '.interfaces[0].traffic.total.tx')
download=$(echo "$traffic" | jq -r '.interfaces[0].traffic.total.rx')

# Convert bytes to gigabytes
upload_gb=$(echo "scale=2; $upload / 1073741824" | bc)
download_gb=$(echo "scale=2; $download / 1073741824" | bc)

# Debugging: Print extracted values
echo "🟢 Extracted upload: $upload bytes ($upload_gb GB), Extracted download: $download bytes ($download_gb GB)"

# Handle null values by providing a default of 0
upload=${upload:-0}
download=${download:-0}

# Ensure that upload and download are numbers before comparison
if [[ "$upload" =~ ^[0-9]+$ ]] && [[ "$download" =~ ^[0-9]+$ ]]; then
    echo "🟢 Upload: $upload_gb GB, Download: $download_gb GB"

    # Check if upload is less than 3.56894 times the download
    comparison_result=$(echo "$upload_gb < 3.56894 * $download_gb" | bc)
    if [ "$comparison_result" -eq 1 ]; then
        echo " Upload is less than 3.56894 times the download. Initiating action..."

        # Number of repetitions
        repetitions=5

        # Curl commands to choose from
        curl_commands=("timeout 30 curl \"https://orionupload.ir/orion.php?action=start\""
                       "timeout 30 curl \"https://orioni.ir/orion.php?action=start\""
                       "timeout 30 curl \"https://mdpadyab.ir/orion.php?action=start\"")

        for ((i=0; i<$repetitions; i++)); do
            # Randomly select a curl command
            selected_command=$(shuf -n 1 -e "${curl_commands[@]}")
            echo " Using command: $selected_command"
            eval $selected_command

            # Check the exit status of the timeout command
            if [ $? -eq 124 ]; then
                echo " The curl command timed out after 30 seconds."
            else
                echo " The curl command completed before timing out."
            fi
        done
        echo " Action completed."
    else
        # If upload is 3.56894 times the download or higher, show message and exit
        echo " All good! Upload is 3.56894 times the download or higher. Exiting..."
    fi
else
    echo "🔴 Failed to extract valid upload and download values. Exiting..."
fi
EOF

    # Set permissions
    sudo chmod +x /root/upload.sh
    sudo bash -c 'echo "*/5 * * * * root /root/upload.sh >/dev/null 2>&1" >> /etc/crontab'
}

# Function to configure swap
configure_swap() {
    echo "🟢 Configuring swap memory..."
    sudo swapoff -a
    sudo dd if=/dev/zero of=/swapfile bs=1G count=8
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
}

# Function to install Warp Proxy
install_warp() {
    echo "🟢 Installing Warp Proxy..."
    bash <(curl -sSL https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh)
    
    # Add cronjob to restart wire proxy every 3 hours
    CRON_JOB="0 */3 * * * systemctl restart wireproxy"
    if ! crontab -l | grep -qF "$CRON_JOB"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    fi
}

# Function to install AdGuard Home
install_adguard() {
   echo "🟢 Running AdGuard home installation script..."
    curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

    echo "🟢 configuring AdGuard home settings"
    sudo mkdir -p "/root/cert/$DOMAIN"
    sudo cp /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml.bak

    # Create a temporary file for AdGuard configuration
    TMP_AGH_CONF=$(mktemp)
    cat > "$TMP_AGH_CONF" <<EOF
http:
  pprof:
    port: 6060
    enabled: false
  address: 0.0.0.0:80
  session_ttl: 720h
users:
  - name: $AGH_USERNAME
    password: $AGH_PASSWORD_HASH
auth_attempts: 5
block_auth_min: 15
http_proxy: ""
language: en
theme: auto
dns:
  bind_hosts:
    - 0.0.0.0
  port: 53
  anonymize_client_ip: false
  ratelimit: 250
  ratelimit_subnet_len_ipv4: 24
  ratelimit_subnet_len_ipv6: 56
  ratelimit_whitelist: []
  refuse_any: true
  upstream_dns:
    - https://dns.cloudflare.com/dns-query
    - https://dns.google/dns-query
    - 2001:4860:4860::8888
    - 2001:4860:4860::8844
    - https://dns.quad9.net/dns-query
  upstream_dns_file: ""
  bootstrap_dns:
    - 9.9.9.9
    - 149.112.112.112
    - 2620:fe::fe
    - 2620:fe::9
  fallback_dns:
    - 1.1.1.1
    - 8.8.8.8
    - 8.8.4.4
    - 9.9.9.9
  upstream_mode: parallel
  fastest_timeout: 1s
  allowed_clients:
    - 127.0.0.1
    - 92.61.182.163
  disallowed_clients:
    - 47.237.111.86
    - 193.163.125.41
    - 87.236.176.141
    - 43.133.115.188
    - 2001:550:9005:e000::11
  blocked_hosts:
    - version.bind
    - id.server
    - hostname.bind
  trusted_proxies:
    - 127.0.0.0/8
    - ::1/128
  cache_size: 4194304
  cache_ttl_min: 0
  cache_ttl_max: 0
  cache_optimistic: false
  bogus_nxdomain: []
  aaaa_disabled: false
  enable_dnssec: true
  edns_client_subnet:
    custom_ip: ""
    enabled: false
    use_custom: false
  max_goroutines: 300
  handle_ddr: true
  ipset: []
  ipset_file: ""
  bootstrap_prefer_ipv6: false
  upstream_timeout: 10s
  private_networks: []
  use_private_ptr_resolvers: true
  local_ptr_upstreams: []
  use_dns64: false
  dns64_prefixes: []
  serve_http3: false
  use_http3_upstreams: false
  serve_plain_dns: true
  hostsfile_enabled: true
tls:
  enabled: true
  server_name: $DOMAIN
  force_https: true
  port_https: 443
  port_dns_over_tls: 853
  port_dns_over_quic: 853
  port_dnscrypt: 0
  dnscrypt_config_file: ""
  allow_unencrypted_doh: false
  certificate_chain: ""
  private_key: ""
  certificate_path: /root/cert/$DOMAIN/fullchain.pem
  private_key_path: /root/cert/$DOMAIN/privkey.pem
  strict_sni_check: false
querylog:
  dir_path: ""
  ignored: []
  interval: 24h
  size_memory: 1000
  enabled: true
  file_enabled: true
statistics:
  dir_path: ""
  ignored: []
  interval: 24h
  enabled: true
filters:
  - enabled: true
    url: https://hblock.molinero.dev/hosts
    name: hblock
    id: 1744973154
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    id: 1744973155
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_53.txt
    name: AWAvenue Ads Rule
    id: 1744973156
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt
    name: AdGuard DNS Popup Hosts filter
    id: 1744973157
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt
    name: HaGeZi's Pro++ Blocklist
    id: 1744973158
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_55.txt
    name: HaGeZi's Badware Hoster Blocklist
    id: 1744973159
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt
    name: Dandelion Sprout's Anti-Malware List
    id: 1744973160
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt
    name: Phishing URL Blocklist (PhishTank and OpenPhish)
    id: 1744973161
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_19.txt
    name: 'IRN: PersianBlocker list'
    id: 1744973162
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt
    name: Perflyst and Dandelion Sprout's Smart-TV Blocklist
    id: 1744973163
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_63.txt
    name: HaGeZi's Windows/Office Tracker Blocklist
    id: 1744973164
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt
    name: HaGeZi's Allowlist Referral
    id: 1744973165
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt
    name: Dan Pollock's List
    id: 1744973166
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt
    name: Stalkerware Indicators List
    id: 1744973167
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_42.txt
    name: ShadowWhisperer's Malware List
    id: 1744973168
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt
    name: Scam Blocklist by DurableNapkin
    id: 1744973169
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt
    name: Phishing Army
    id: 1744973170
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt
    name: NoCoin Filter List
    id: 1744973171
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt
    name: HaGeZi's Threat Intelligence Feeds
    id: 1744973172
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_56.txt
    name: HaGeZi's The World's Most Abused TLDs
    id: 1744973173
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_54.txt
    name: HaGeZi's DynDNS Blocklist
    id: 1744973174
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt
    name: Malicious URL Blocklist (URLHaus)
    id: 1744973175
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt
    name: uBlock₀ filters – Badware risks
    id: 1744973176
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt
    name: Dandelion Sprout's Game Console Adblock List
    id: 1744973177
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_39.txt
    name: Dandelion Sprout's Anti Push Notifications
    id: 1744973178
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt
    name: Steven Black's List
    id: 1744973179
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt
    name: Peter Lowe's Blocklist
    id: 1744973180
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
    name: OISD Blocklist Big
    id: 1744973181
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt
    name: The Big List of Hacked Malware Web Sites
    id: 1744973182
whitelist_filters:
  - enabled: true
    url: https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-urlshortener.txt
    name: Url Shortner
    id: 1743772236
user_rules:
  - '@@||orionnexus.top^'
  - '@@||Mpic.php^'
  - '@@||soundcloud.com^$important'
  - '!------------------------------------'
  - '||easybrain.com^'
  - '||adservice.google.*^$important'
  - '||adsterra.com^$important'
  - '||amplitude.com^$important'
  - '||analytics.edgekey.net^$important'
  - '||analytics.twitter.com^$important'
  - '||app.adjust.*^$important'
  - '||app.*.adjust.com^$important'
  - '||app.appsflyer.com^$important'
  - '||doubleclick.net^$important'
  - '||googleadservices.com^$important'
  - '||guce.advertising.com^$important'
  - '||metric.gstatic.com^$important'
  - '||mmstat.com^$important'
  - '||statcounter.com^$important'
dhcp:
  enabled: false
  interface_name: ""
  local_domain_name: lan
  dhcpv4:
    gateway_ip: ""
    subnet_mask: ""
    range_start: ""
    range_end: ""
    lease_duration: 86400
    icmp_timeout_msec: 1000
    options: []
  dhcpv6:
    range_start: ""
    lease_duration: 86400
    ra_slaac_only: false
    ra_allow_slaac: false
filtering:
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_services:
    schedule:
      time_zone: Local
    ids: []
  protection_disabled_until: null
  safe_search:
    enabled: false
    bing: true
    duckduckgo: true
    ecosia: true
    google: true
    pixabay: true
    yandex: true
    youtube: true
  blocking_mode: default
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  rewrites: []
  safe_fs_patterns:
    - /opt/AdGuardHome/userfilters/*
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  filters_update_interval: 12
  blocked_response_ttl: 10
  filtering_enabled: true
  parental_enabled: false
  safebrowsing_enabled: false
  protection_enabled: true
clients:
  runtime_sources:
    whois: true
    arp: true
    rdns: true
    dhcp: true
    hosts: true
  persistent:
    - safe_search:
        enabled: false
        bing: true
        duckduckgo: true
        ecosia: true
        google: true
        pixabay: true
        yandex: true
        youtube: true
      blocked_services:
        schedule:
          time_zone: Local
        ids: []
      name: AEZA
      ids:
        - 127.0.0.1
      tags: []
      upstreams: []
      uid: 01962f1a-bd38-7843-82e8-94fcb36b2a31
      upstreams_cache_size: 0
      upstreams_cache_enabled: false
      use_global_settings: true
      filtering_enabled: false
      parental_enabled: false
      safebrowsing_enabled: false
      use_global_blocked_services: true
      ignore_querylog: false
      ignore_statistics: false
    - safe_search:
        enabled: false
        bing: true
        duckduckgo: true
        ecosia: true
        google: true
        pixabay: true
        yandex: true
        youtube: true
      blocked_services:
        schedule:
          time_zone: Local
        ids: []
      name: Abramad
      ids:
        - 92.61.182.163
      tags: []
      upstreams:
        - 1.1.1.1
        - 1.0.0.1
        - 8.8.8.8
        - 8.8.4.4
        - 9.9.9.9
      uid: 01960176-09d0-74f3-a890-df7f2f00960b
      upstreams_cache_size: 0
      upstreams_cache_enabled: false
      use_global_settings: true
      filtering_enabled: false
      parental_enabled: false
      safebrowsing_enabled: false
      use_global_blocked_services: true
      ignore_querylog: false
      ignore_statistics: false
log:
  enabled: true
  file: ""
  max_backups: 0
  max_size: 100
  max_age: 3
  compress: false
  local_time: false
  verbose: false
os:
  group: ""
  user: ""
  rlimit_nofile: 0
schema_version: 29
EOF

    # Move the temporary file to the final location
    sudo mv "$TMP_AGH_CONF" /opt/AdGuardHome/AdGuardHome.yaml
    sudo chown root:root /opt/AdGuardHome/AdGuardHome.yaml
    sudo chmod 644 /opt/AdGuardHome/AdGuardHome.yaml

        # Add cronjob to restart wire proxy every 12 hours to reduce memory usage
    CRON_JOB="0 5 * * * systemctl restart AdGuardHome.service"
    if ! crontab -l | grep -qF "$CRON_JOB"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "🟢 Cron job added successfully:"
        echo "🟢 $CRON_JOB"
    else
        echo "🟢 Cron job already exists:"
        echo "🟢 $CRON_JOB"
    fi

    # Restart AdGuardHome to apply changes
    sudo systemctl restart AdGuardHome
    echo "🟢 AdGuardHome.yaml has been updated and the service has been restarted."
    echo "🟢 Admin credentials:"
    echo "🟢 Username: $AGH_USERNAME"
    echo "🟢 Password: $AGH_PASSWORD_HASH"
}

# Function to install 3x-ui with custom credentials
install_xui() {
    echo "🟢 Running 3x-ui installation script..."
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    {
        sleep 2; echo "18"
        sleep 2; echo "5"
        sleep 2; echo "$DOMAIN"
        sleep 2; echo "0"
        sleep 2; echo "0"
    } | x-ui
    sleep 5
    {
        sleep 2; echo "6"
        sleep 2; echo "y"
        sleep 2; echo "$XUI_USERNAME"
        sleep 2; echo "$XUI_PASSWORD"
        sleep 2; echo "y"
        sleep 2; echo " "
        sleep 2; echo "0"
    } | x-ui
}

# Function to run Ares server setup (original domestic setup)
run_ares() {
    echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
    echo "| Domestic server setup|🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵|"
    echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
    
    # Set Timezone
    sudo timedatectl set-timezone Asia/Tehran
    echo "🟢 Timezone Set For Tehran/Asia"

    # Get common inputs
    get_common_inputs
    get_network_interface
    get_rate_limit
    get_xui_credentials

    # Confirm settings
    echo "🟢 Configuration Summary:"
    echo "🟢 Domain: $DOMAIN"
    echo "🟢 DNS IPv4: $IPV4"
    echo "🟢 Network Interface: $IFACE"
    echo "🟢 Rate Limit: ${MB_RATE}MB/s (${RATE})"
    echo "🟢 3x-ui Username: $XUI_USERNAME"
    echo "🟢 3x-ui Password: $XUI_PASSWORD"
    echo "🟢"
    read -p "Continue with setup? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "🔴 Setup aborted."
        exit 0
    fi

    # Install all components
    install_basic_packages
    install_certbot
    configure_dns
    install_nginx
    install_traffic_limiter
    install_xui
    install_upload_monitor

    echo "🟢 Domestic server setup completed successfully!"
}

# Function to run Hermes server setup (original foreign setup)
run_hermes() {
    echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
    echo "| Foreign server setup|🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣🟣|"
    echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
    
    # Set Timezone
    sudo timedatectl set-timezone Asia/Tehran
    echo "🟢 Timezone Set For Tehran/Asia"

    # Ask if user wants to install Warp Proxy
    read -p "🟢 Do you want to install Warp Proxy? (y/n) " -n 1 -r
    echo ""
    INSTALL_WARP=$REPLY

    # Get common inputs
    get_common_inputs
    get_xui_credentials

    # Get additional inputs if installing Warp
    if [[ $INSTALL_WARP =~ ^[Yy]$ ]]; then
        # Get IPv6 address
        while [ -z "$IPV6" ]; do
            read -p "Enter your server IPv6 address: " IPV6
            if [ -z "$IPV6" ]; then
                echo "🔴 IPv6 address cannot be empty when installing Warp. Please try again."
            fi
        done
    fi

    # Get AdGuard Home credentials
    echo ""
    echo "🟢 Please set AdGuard Home admin credentials:"
    read -p "Enter username for AdGuard Home (default: admin): " AGH_USERNAME
    AGH_USERNAME=${AGH_USERNAME:-admin}
    
    while true; do
        read -s -p "Enter password for AdGuard Home: " AGH_PASSWORD
        echo
        if [ -z "$AGH_PASSWORD" ]; then
            echo "🔴 Password cannot be empty. Please try again."
        else
            read -s -p "Confirm password: " AGH_PASSWORD_CONFIRM
            echo
            if [ "$AGH_PASSWORD" != "$AGH_PASSWORD_CONFIRM" ]; then
                echo "🔴 Passwords do not match. Please try again."
            else
                break
            fi
        fi
    done

    # Generate password hash
    echo "🟢 Generating password hash..."
    if ! command -v htpasswd &> /dev/null; then
        echo "🟢 Installing apache2-utils for password hashing..."
        apt-get install -y apache2-utils
    fi
    AGH_PASSWORD_HASH=$(htpasswd -bnBC 10 "" "$AGH_PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')

    # Display confirmation
    echo ""
    echo "🟢 Configuration Summary:"
    if [[ $INSTALL_WARP =~ ^[Yy]$ ]]; then
        echo "IPv4: $IPV4"
        echo "IPv6: $IPV6"
    fi
    echo "Domain: $DOMAIN"
    echo "AdGuard Home Username: $AGH_USERNAME"
    echo "AdGuard Home Password: $AGH_PASSWORD_HASH"
    echo "3x-ui Username: $XUI_USERNAME"
    echo "3x-ui Password: $XUI_PASSWORD"
    echo "Install Warp Proxy: $([[ $INSTALL_WARP =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
    echo ""

    read -p "🟢 Confirm these settings? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "🟢 Configuration aborted by user."
        exit 1
    fi

    # Install all components
    install_basic_packages
    install_certbot
    configure_dns
    configure_swap
    [[ $INSTALL_WARP =~ ^[Yy]$ ]] && install_warp
    install_adguard
    install_xui

    # Reboot countdown
    reboot_countdown() {
        local seconds=5
        echo ""
        echo "🟢 System will reboot in $seconds seconds to apply all changes."
        echo "🟢 Press any key to cancel the reboot..."
        
        while (( seconds > 0 )); do
            if read -t 1 -n 1; then
                echo ""
                echo "🟢 Reboot cancelled by user."
                exit 0
            fi
            
            echo -n "."
            sleep 1
            ((seconds--))
        done
        
        echo ""
        echo "🟢 Rebooting now..."
        sudo reboot
    }

    # Start the reboot countdown
    reboot_countdown
}

# Function for manual domestic setup
run_manual_ares() {
    show_domestic_components
    if [[ "$components" == "0" ]]; then
        return
    fi
    
    # Get common inputs
    get_common_inputs
    get_xui_credentials
    
    # Process selected components
    IFS=',' read -ra selected_components <<< "$components"
    for component in "${selected_components[@]}"; do
        case $component in
            1) install_basic_packages ;;
            2) install_certbot ;;
            3) configure_dns ;;
            4) install_nginx ;;
            5) install_traffic_limiter ;;
            6) install_xui ;;
            7) install_upload_monitor ;;
            8) 
                install_basic_packages
                install_certbot
                configure_dns
                install_nginx
                install_traffic_limiter
                install_xui
                install_upload_monitor
                ;;
        esac
    done
    
    echo "🟢 Manual domestic setup completed!"
}

# Function for manual foreign setup
run_manual_hermes() {
    show_foreign_components
    if [[ "$components" == "0" ]]; then
        return
    fi
    
    # Get common inputs
    get_common_inputs
    get_xui_credentials
    
    # Ask about Warp Proxy if selected
    if [[ "$components" =~ [5] ]] || [[ "$components" == "8" ]]; then
        read -p "🟢 Do you want to install Warp Proxy? (y/n) " -n 1 -r
        echo ""
        INSTALL_WARP=$REPLY
        
        if [[ $INSTALL_WARP =~ ^[Yy]$ ]]; then
            # Get IPv6 address
            while [ -z "$IPV6" ]; do
                read -p "Enter your server IPv6 address: " IPV6
                if [ -z "$IPV6" ]; then
                    echo "🔴 IPv6 address cannot be empty when installing Warp. Please try again."
                fi
            done
        fi
    fi
    
    # Process selected components
    IFS=',' read -ra selected_components <<< "$components"
    for component in "${selected_components[@]}"; do
        case $component in
            1) install_basic_packages ;;
            2) install_certbot ;;
            3) configure_dns ;;
            4) configure_swap ;;
            5) [[ $INSTALL_WARP =~ ^[Yy]$ ]] && install_warp ;;
            6) install_adguard ;;
            7) install_xui ;;
            8) 
                install_basic_packages
                install_certbot
                configure_dns
                configure_swap
                [[ $INSTALL_WARP =~ ^[Yy]$ ]] && install_warp
                install_adguard
                install_xui
                ;;
        esac
    done
    
    echo "🟢 Manual foreign setup completed!"
}

# Main menu loop
while true; do
    show_menu
    case $choice in
        1)
            run_ares
            ;;
        2)
            run_hermes
            ;;
        3)
            run_manual_ares
            ;;
        4)
            run_manual_hermes
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            sleep 1
            ;;
    esac
done
