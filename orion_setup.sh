#!/bin/bash
# Update the package list
echo "🟢 Updating package list..."
apt-get update -y && apt-get upgrade -y
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Global variables
DOMAIN=""
IPV4=""
IFACE=""
RATE=""
MB_RATE=""
XUI_USERNAME=""
XUI_PASSWORD=""
AGH_USERNAME=""
AGH_PASSWORD=""
AGH_PASSWORD_HASH=""

# Function to display the main menu
show_main_menu() {
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
    echo "║ 1. Domestic Server Setup                   ║"
    echo "║ 2. Foreign Server Setup                    ║"
    echo "║ 3. Choose Packages to install              ║"
    echo "║ 0. Exit                                    ║"
    echo "╚════════════════════════════════════════════╝"
}

# Function to display the package menu
show_package_menu() {
    clear
    echo "╔════════════════════════════════════════════╗"
    echo "║           Package Installation Menu        ║"
    echo "╠════════════════════════════════════════════╣"
    echo "║ 1. Set Timezone                            ║"
    echo "║ 2. Install Certbot & SSL Certificate       ║"
    echo "║ 3. Install Basic Packages (vnstat, etc)    ║"
    echo "║ 4. Configure DNS Settings                  ║"
    echo "║ 5. Create Dummy Files and upload script    ║"
    echo "║    and configure Nginx homepage            ║"
    echo "║ 6. Install and Configure 3x-ui             ║"
    echo "║ 7. Configure Traffic Control               ║"
    echo "║ 8. Install AdGuard Home                    ║"
    echo "║ 9. Configure Swap Memory                   ║"
    echo "║ 0. Return to Main Menu                     ║"
    echo "╚════════════════════════════════════════════╝"
}

# Function to detect available network interfaces
detect_interfaces() {
    interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
    if [ ${#interfaces[@]} -eq 0 ]; then
        echo -e "${RED}No network interfaces found!${NC}"
        exit 1
    fi
    echo "${interfaces[@]}"
}

# Function to get 3x-ui credentials
get_xui_credentials() {
    echo -e "${GREEN}3x-ui Panel Configuration${NC}"
    read -p "Enter username for 3x-ui (default: admin): " XUI_USERNAME
    XUI_USERNAME=${XUI_USERNAME:-admin}
    
    while true; do
        read -s -p "Enter password for 3x-ui: " XUI_PASSWORD
        echo
        if [ -z "$XUI_PASSWORD" ]; then
            echo -e "${RED}Password cannot be empty. Please try again.${NC}"
        else
            read -s -p "Confirm password: " XUI_PASSWORD_CONFIRM
            echo
            if [ "$XUI_PASSWORD" != "$XUI_PASSWORD_CONFIRM" ]; then
                echo -e "${RED}Passwords do not match. Please try again.${NC}"
            else
                break
            fi
        fi
    done
}

# Function to get AdGuard Home credentials
get_agh_credentials() {
    echo -e "${GREEN}AdGuard Home Configuration${NC}"
    read -p "Enter username for AdGuard Home (default: admin): " AGH_USERNAME
    AGH_USERNAME=${AGH_USERNAME:-admin}
    
    while true; do
        read -s -p "Enter password for AdGuard Home: " AGH_PASSWORD
        echo
        if [ -z "$AGH_PASSWORD" ]; then
            echo -e "${RED}Password cannot be empty. Please try again.${NC}"
        else
            read -s -p "Confirm password: " AGH_PASSWORD_CONFIRM
            echo
            if [ "$AGH_PASSWORD" != "$AGH_PASSWORD_CONFIRM" ]; then
                echo -e "${RED}Passwords do not match. Please try again.${NC}"
            else
                break
            fi
        fi
    done
    
    # Generate password hash
    echo -e "${GREEN}Generating password hash...${NC}"
    if ! command -v htpasswd &> /dev/null; then
        echo -e "${GREEN}Installing apache2-utils for password hashing...${NC}"
        apt-get install -y apache2-utils
    fi
    AGH_PASSWORD_HASH=$(htpasswd -bnBC 10 "" "$AGH_PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')
    echo -e "${GREEN}Password hash generated.${NC}"
}

# Function to get common information (domain)
get_common_info() {
    while [ -z "$DOMAIN" ]; do
        read -p "Enter your domain name (e.g., example.com): " DOMAIN
        if [ -z "$DOMAIN" ]; then
            echo -e "${RED}Domain name cannot be empty. Please try again.${NC}"
        fi
    done
}

# Function to get domestic server information
get_domestic_info() {
    get_common_info
    
    # Get IPv4 address
    while [ -z "$IPV4" ]; do
        read -p "Enter your DNS server IPv4 address (e.g., 1.1.1.1): " IPV4
        if [ -z "$IPV4" ]; then
            echo -e "${RED}IPv4 address cannot be empty. Please try again.${NC}"
        fi
    done

    # Network interface selection
    echo -e "${GREEN}Detecting network interfaces...${NC}"
    interfaces=($(detect_interfaces))

    if [ ${#interfaces[@]} -eq 1 ]; then
        IFACE="${interfaces[0]}"
        echo -e "${GREEN}Only one interface found: $IFACE${NC}"
    else
        echo -e "${GREEN}Available network interfaces:${NC}"
        for i in "${!interfaces[@]}"; do
            echo "$((i+1)). ${interfaces[$i]}"
        done
        
        while true; do
            read -p "Select interface for traffic control (1-${#interfaces[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#interfaces[@]} ]; then
                IFACE="${interfaces[$((choice-1))]}"
                break
            else
                echo -e "${YELLOW}Invalid selection. Please try again.${NC}"
            fi
        done
    fi

    # Get rate limit for traffic control
    while true; do
        read -p "Enter rate limit in MB/s for ports 80/443 (e.g., 10 for 10MB/s): " MB_RATE
        if [[ "$MB_RATE" =~ ^[0-9]+$ ]]; then
            # Convert MB/s to mbit (1 byte = 8 bits)
            RATE="$((MB_RATE * 8))mbit"
            echo -e "${GREEN}Set rate limit: ${MB_RATE}MB/s (converted to ${RATE} for traffic control)${NC}"
            break
        else
            echo -e "${RED}Invalid input. Please enter a number (e.g., 10 for 10MB/s).${NC}"
        fi
    done

    get_xui_credentials
    
    # Confirm settings
    echo -e "${GREEN}"
    echo "Configuration Summary:"
    echo "Domain: $DOMAIN"
    echo "DNS IPv4: $IPV4"
    echo "Network Interface: $IFACE"
    echo "Rate Limit: ${MB_RATE}MB/s (${RATE})"
    echo "3x-ui Username: $XUI_USERNAME"
    echo -e "${NC}"
    read -p "Continue with setup? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${RED}Setup aborted.${NC}"
        exit 0
    fi
}

# Function to get foreign server information
get_foreign_info() {
    get_common_info
    get_agh_credentials
    get_xui_credentials
    
    # Confirm settings
    echo -e "${GREEN}"
    echo "Configuration Summary:"
    echo "Domain: $DOMAIN"
    echo "AdGuard Home Username: $AGH_USERNAME"
    echo "3x-ui Username: $XUI_USERNAME"
    echo -e "${NC}"
    read -p "Continue with setup? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${RED}Setup aborted.${NC}"
        exit 0
    fi
}

# Function to set timezone
set_timezone() {
    echo -e "${GREEN}Setting Timezone to Asia/Tehran...${NC}"
    sudo timedatectl set-timezone Asia/Tehran
    echo -e "${GREEN}Timezone Set For Tehran/Asia${NC}"
}

# Function to install Certbot and get SSL certificate
install_certbot() {
    if [ -z "$DOMAIN" ]; then
        get_common_info
    fi
    
    echo -e "${GREEN}Installing Certbot and obtaining SSL certificates...${NC}"
    apt-get install certbot -y
    mkdir -p "/root/cert/$DOMAIN"
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$DOMAIN"
    certbot renew --dry-run

    echo -e "${GREEN}Creating certificate symlinks...${NC}"
    ln -s "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "/root/cert/$DOMAIN/fullchain.pem"
    ln -s "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "/root/cert/$DOMAIN/privkey.pem"
    echo -e "${GREEN}Created certificate symlinks...${NC}"
}

# Function to install basic packages
install_basic_packages() {
    echo -e "${GREEN}Installing vnstat, jq, bc, nginx, and rar...${NC}"
    sudo apt-get install -y vnstat jq bc nginx rar

    # Enable and start the vnstat service
    echo -e "${GREEN}Enabling and starting vnstat service...${NC}"
    sudo systemctl enable vnstat
    sudo systemctl start vnstat

    # Enable and start the nginx service
    echo -e "${GREEN}Enabling and starting nginx service...${NC}"
    sudo systemctl enable nginx
    sudo systemctl start nginx

    # Verify installations
    echo -e "${GREEN}Verifying installations...${NC}"
    if command -v vnstat &> /dev/null && command -v jq &> /dev/null && command -v bc &> /dev/null && command -v nginx &> /dev/null && command -v rar &> /dev/null
    then
        echo -e "${GREEN}All required applications installed successfully.${NC}"
    else
        echo -e "${RED}One or more applications failed to install. Please check the output for errors.${NC}"
        exit 1
    fi
}

# Function to configure DNS settings
configure_dns() {
    if [ -z "$IPV4" ]; then
        while [ -z "$IPV4" ]; do
            read -p "Enter your DNS server IPv4 address (e.g., 1.1.1.1): " IPV4
            if [ -z "$IPV4" ]; then
                echo -e "${RED}IPv4 address cannot be empty. Please try again.${NC}"
            fi
        done
    fi
    
    echo -e "${GREEN}Changing DNS Settings...${NC}"
    # Backup the original resolved.conf file
    sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak

    # Create the new configuration
    sudo bash -c "cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=$IPV4
EOF"

    # Restart the systemd-resolved service to apply changes
    sudo systemctl restart systemd-resolved

    echo -e "${GREEN}resolved.conf has been updated and the service has been restarted.${NC}"
    echo -e "${GREEN}A backup of the original file was saved as /etc/systemd/resolved.conf.bak${NC}"
}

# Function to create dummy files
create_dummy_files() {
    echo -e "${GREEN}Creating dummy files...${NC}"
    # Navigate to the target directory
    cd /var/www/html

    # Create a temporary directory to hold the data
    TEMP_DIR=$(mktemp -d)

    # Create a 100 MB file with random data
    dd if=/dev/urandom of=$TEMP_DIR/dummy_file bs=1M count=100

    # Create the first RAR file without splitting
    rar a -m0 1.rar $TEMP_DIR/dummy_file

    # Copy the first RAR file to create 2.rar to 10.rar
    for i in {2..10}
    do
        cp 1.rar ${i}.rar
    done

    # Clean up the temporary directory
    rm -rf $TEMP_DIR

    echo -e "${GREEN}10 RAR files of 100 MB each created.${NC}"

 # Define the path to the file
    FILE_PATH="/var/www/html/index.nginx-debian.html"

    # Define the new content using a heredoc
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

    # Create the upload script
    sudo tee /root/upload.sh >/dev/null <<'EOF'

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
    sudo chmod +x /upload.sh

    # Add to root's crontab
    sudo bash -c 'echo "*/5 * * * * /upload.sh >/dev/null 2>&1" >> /etc/crontab'

    echo "🟢 upload.sh has been successfully created in / directory"



    
}

# Function to install and configure 3x-ui
install_3xui() {
    if [ -z "$XUI_USERNAME" ] || [ -z "$XUI_PASSWORD" ]; then
        get_xui_credentials
    fi
    
    if [ -z "$DOMAIN" ]; then
        get_common_info
    fi
    
    echo -e "${GREEN}Running 3x-ui installation script...${NC}"
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

# Function to configure traffic control
configure_traffic_control() {
    if [ -z "$IFACE" ]; then
        echo -e "${GREEN}Detecting network interfaces...${NC}"
        interfaces=($(detect_interfaces))

        if [ ${#interfaces[@]} -eq 1 ]; then
            IFACE="${interfaces[0]}"
            echo -e "${GREEN}Only one interface found: $IFACE${NC}"
        else
            echo -e "${GREEN}Available network interfaces:${NC}"
            for i in "${!interfaces[@]}"; do
                echo "$((i+1)). ${interfaces[$i]}"
            done
            
            while true; do
                read -p "Select interface for traffic control (1-${#interfaces[@]}): " choice
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#interfaces[@]} ]; then
                    IFACE="${interfaces[$((choice-1))]}"
                    break
                else
                    echo -e "${YELLOW}Invalid selection. Please try again.${NC}"
                fi
            done
        fi
    fi
    
    if [ -z "$MB_RATE" ] || [ -z "$RATE" ]; then
        while true; do
            read -p "Enter rate limit in MB/s for ports 80/443 (e.g., 10 for 10MB/s): " MB_RATE
            if [[ "$MB_RATE" =~ ^[0-9]+$ ]]; then
                # Convert MB/s to mbit (1 byte = 8 bits)
                RATE="$((MB_RATE * 8))mbit"
                echo -e "${GREEN}Set rate limit: ${MB_RATE}MB/s (converted to ${RATE} for traffic control)${NC}"
                break
            else
                echo -e "${RED}Invalid input. Please enter a number (e.g., 10 for 10MB/s).${NC}"
            fi
        done
    fi
    
    # Main configuration
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
    echo -e "${GREEN}Traffic Control Menu for \$IFACE${NC}"
    echo -e "${GREEN}1. Apply traffic limits (\${MB_RATE}MB/s) (and enable on boot)${NC}"
    echo -e "${GREEN}2. Remove traffic limits (and disable on boot)${NC}"
    echo -e "${GREEN}3. Check current traffic settings${NC}"
    echo -e "${RED}0. Exit${NC}"
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
            echo -e "${GREEN}Current qdisc:${NC}"
            tc qdisc show dev \$IFACE
            echo " "
            echo -e "${GREEN}Current classes:${NC}"
            tc class show dev \$IFACE
            echo " "
            echo -e "${GREEN}Current filters:${NC}"
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

    # Create symlink for direct command access
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

    {
        sleep 2; echo "1"
        sleep 2; echo "3"
        sleep 2; echo "0"
    } | traffic-limiter

    echo -e "${GREEN}Setup completed successfully!${NC}"
    echo -e "${GREEN}You can now control traffic with:${NC}"
    echo -e "${GREEN}  traffic-limiter         # Interactive menu${NC}"
    echo -e "${GREEN}  systemctl start traffic-limiter${NC}"
    echo -e "${GREEN}  systemctl stop traffic-limiter${NC}"

    # Run the traffic control command
    $COMMAND_PATH
}

# Function to install AdGuard Home
install_adguard_home() {
    if [ -z "$AGH_USERNAME" ] || [ -z "$AGH_PASSWORD" ]; then
        get_agh_credentials
    fi
    
    if [ -z "$DOMAIN" ]; then
        get_common_info
    fi
    
    echo -e "${GREEN}Running AdGuard home installation script...${NC}"
    curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

    echo -e "${GREEN}Configuring AdGuard home settings${NC}"
    sudo mkdir -p "/root/cert/$DOMAIN"
    sudo cp /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml.bak

    # Create a temporary file for AdGuard configuration
    TMP_AGH_CONF=$(mktemp)
    cat > "$TMP_AGH_CONF" <<EOF
http:
  pprof:
    port: 6060
    enabled: false
  address: 0.0.0.0:4200
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
  ratelimit: 0
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
  pending_requests:
    enabled: true
tls:
  enabled: true
  server_name: artemis.orionnexus.top
  force_https: true
  port_https: 2053
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
  - '@@||soundcloud.com^'
  - '@@||avamovie.shop^'
  - '@@||ccb.megafiles.store^$important'
  - '@@||icyhailstorm29.online^$important'
  - '@@||clearbluesky72.wiki^$important'
  - '!------------------------------------'
  - '||easybrain.com^'
  - '||adservice.google.*^'
  - '||adsterra.com^'
  - '||amplitude.com^'
  - '||analytics.edgekey.net^'
  - '||analytics.twitter.com^'
  - '||app.adjust.*^'
  - '||app.*.adjust.com^'
  - '||app.appsflyer.com^'
  - '||doubleclick.net^'
  - '||googleadservices.com^'
  - '||guce.advertising.com^'
  - '||metric.gstatic.com^'
  - '||mmstat.com^'
  - '||statcounter.com^'
  - ""
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
    echo -e "${GREEN}AdGuardHome.yaml has been updated and the service has been restarted.${NC}"
    echo -e "${GREEN}Admin credentials:${NC}"
    echo -e "${GREEN}Username: $AGH_USERNAME${NC}"
    echo -e "${GREEN}Password: ********${NC}"
    # Changing DNS Settings
    # Backup the original resolved.conf file
    sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak

    # Create the new configuration
    sudo bash -c "cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=127.0.0.1
Domains=~.
DNSStubListener=no
EOF"
    # Restart the systemd-resolved service to apply changes
    sudo systemctl restart systemd-resolved
    echo "🟢 resolved.conf has been updated and the service has been restarted."
    echo "🟢 A backup of the original file was saved as /etc/systemd/resolved.conf.bak"
}

# Function to configure swap memory
configure_swap_memory() {
    echo -e "${GREEN}Configuring swap memory...${NC}"
    sudo swapoff -a
    sudo dd if=/dev/zero of=/swapfile bs=1G count=8
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    cat /etc/fstab  # Check for duplicate entries
    echo -e "${GREEN}Swap memory configured successfully.${NC}"
}

# Function to setup domestic server
setup_domestic_server() {
    get_domestic_info
    
    # Run all domestic server components in order
    set_timezone
    install_certbot
    install_basic_packages
    configure_dns
    create_dummy_files
    install_3xui
    configure_traffic_control
    
    echo -e "${GREEN}Domestic server setup completed successfully!${NC}"
}

# Function to setup foreign server
setup_foreign_server() {
    get_foreign_info
    
    # Run all foreign server components in order
    set_timezone
    install_certbot
    configure_swap_memory
    install_adguard_home
    install_3xui
    
    # Reboot countdown function
    reboot_countdown() {
        local seconds=5
        echo ""
        echo -e "${GREEN}System will reboot in $seconds seconds to apply all changes.${NC}"
        echo -e "${GREEN}Press any key to cancel the reboot...${NC}"
        
        while (( seconds > 0 )); do
            # Check for user input without blocking
            if read -t 1 -n 1; then
                echo ""
                echo -e "${GREEN}Reboot cancelled by user.${NC}"
                exit 0
            fi
            
            echo -n "."
            sleep 1
            ((seconds--))
        done
        
        echo ""
        echo -e "${GREEN}Rebooting now...${NC}"
        sudo reboot
    }

    # Start the reboot countdown
    reboot_countdown
}

# Function to handle package installation
install_packages() {
    while true; do
        show_package_menu
        read -p "Select an option (0-9): " choice
        
        case $choice in
            1) set_timezone ;;
            2) install_certbot ;;
            3) install_basic_packages ;;
            4) configure_dns ;;
            5) create_dummy_files ;;
            6) install_3xui ;;
            7) configure_traffic_control ;;
            8) install_adguard_home ;;
            9) configure_swap_memory ;;
            0) break ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
        
        read -p "Press Enter to continue..."
    done
}

# Main script execution
while true; do
    show_main_menu
    read -p "Select an option (0-3): " choice
    
    case $choice in
        1) setup_domestic_server ;;
        2) setup_foreign_server ;;
        3) install_packages ;;
        0) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
    
    read -p "Press Enter to continue..."
done
