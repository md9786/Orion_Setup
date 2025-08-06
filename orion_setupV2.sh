#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
    echo "║ 3. Choose Packages to Install              ║"
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
    echo "║ 3. Configure DNS Settings                  ║"
    echo "║ 4. Install AdGuard Home                    ║"
    echo "║ 5. Install and Configure 3x-ui             ║"
    echo "║ 6. Configure Backhaul                      ║"
    echo "║ 7. Disable ICMP                            ║"
    echo "║ 8. Install and Configure Psiphon           ║"
    echo "║ 0. Return to Main Menu                     ║"
    echo "╚════════════════════════════════════════════╝"
}

# Function to check for existing certificates
check_existing_certs() {
    echo -e "${GREEN}Checking for existing SSL certificates...${NC}"
    if [ -d "/etc/letsencrypt/live" ] && [ "$(ls -A /etc/letsencrypt/live)" ]; then
        echo -e "${GREEN}Existing certificates found:${NC}"
        ls /etc/letsencrypt/live
        while true; do
            read -p "Do you want to use an existing certificate? (y/n): " USE_EXISTING_CERT
            case $USE_EXISTING_CERT in
                [Yy]*)
                    while [ -z "$CERTBOT_DOMAIN" ]; do
                        read -p "Enter the domain of the existing certificate to use: " CERTBOT_DOMAIN
                        if [ -d "/etc/letsencrypt/live/$CERTBOT_DOMAIN" ]; then
                            echo -e "${GREEN}Using existing certificate for $CERTBOT_DOMAIN${NC}"
                            break
                        else
                            echo -e "${RED}No certificate found for $CERTBOT_DOMAIN. Please try again.${NC}"
                            CERTBOT_DOMAIN=""
                        fi
                    done
                    break
                    ;;
                [Nn]*)
                    echo -e "${GREEN}Will request new certificate.${NC}"
                    break
                    ;;
                *)
                    echo -e "${RED}Please answer y or n.${NC}"
                    ;;
            esac
        done
    fi
}

# Function to get common information
get_common_info() {
    if [ -z "$USE_EXISTING_CERT" ] || [ "$USE_EXISTING_CERT" = "n" ]; then
        while [ -z "$CERTBOT_DOMAIN" ]; do
            read -p "Enter your domain for Certbot (e.g., example.com): " CERTBOT_DOMAIN
            if [ -z "$CERTBOT_DOMAIN" ]; then
                echo -e "${RED}Certbot domain cannot be empty. Please try again.${NC}"
            fi
        done
    fi
}

# Function to get DNS information
get_dns_info() {
    while true; do
        read -p "Do you want to configure DNS settings? (y/n): " CONFIG_DNS
        case $CONFIG_DNS in
            [Yy]*)
                while [ -z "$IPV4" ]; do
                    read -p "Enter your DNS server IPv4 address (e.g., 1.1.1.1): " IPV4
                    if [ -z "$IPV4" ]; then
                        echo -e "${RED}IPv4 address cannot be empty. Please try again.${NC}"
                    fi
                done
                break
                ;;
            [Nn]*)
                echo -e "${GREEN}Skipping DNS configuration...${NC}"
                break
                ;;
            *)
                echo -e "${RED}Please answer y or n.${NC}"
                ;;
        esac
    done
}

# Function to get AdGuard Home credentials
get_agh_credentials() {
    while true; do
        read -p "Do you want to configure AdGuard Home? (y/n): " CONFIG_AGH
        case $CONFIG_AGH in
            [Yy]*)
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
                
                echo -e "${GREEN}Generating password hash...${NC}"
                if ! command -v htpasswd &> /dev/null; then
                    echo -e "${GREEN}Installing apache2-utils for password hashing...${NC}"
                    apt-get install -y apache2-utils
                fi
                AGH_PASSWORD_HASH=$(htpasswd -bnBC 10 "" "$AGH_PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')
                echo -e "${GREEN}Password hash generated.${NC}"
                break
                ;;
            [Nn]*)
                echo -e "${GREEN}Skipping AdGuard Home configuration...${NC}"
                break
                ;;
            *)
                echo -e "${RED}Please answer y or n.${NC}"
                ;;
        esac
    done
}

# Function to get Backhaul configuration
get_backhaul_config() {
    while true; do
        read -p "Do you want to configure Backhaul? (y/n): " CONFIG_BACKHAUL
        case $CONFIG_BACKHAUL in
            [Yy]*)
                while [ -z "$BACKHAUL_DOMAIN" ]; do
                    read -p "Enter your domain or IP for Backhaul (e.g., backhaul.example.com or 1.2.3.4): " BACKHAUL_DOMAIN
                    if [ -z "$BACKHAUL_DOMAIN" ]; then
                        echo -e "${RED}Backhaul domain/IP cannot be empty. Please try again.${NC}"
                    fi
                done
                
                while [ -z "$BACKHAUL_PORT" ]; do
                    read -p "Enter the port for Backhaul: " BACKHAUL_PORT
                    if [ -z "$BACKHAUL_PORT" ]; then
                        echo -e "${RED}Port cannot be empty. Please try again.${NC}"
                    fi
                done
                
                while [ -z "$BACKHAUL_TOKEN" ]; do
                    read -p "Enter the secret token for Backhaul (must be the same on both servers): " BACKHAUL_TOKEN
                    if [ -z "$BACKHAUL_TOKEN" ]; then
                        echo -e "${RED}Token cannot be empty. Please try again.${NC}"
                    fi
                done
                break
                ;;
            [Nn]*)
                echo -e "${GREEN}Skipping Backhaul configuration...${NC}"
                break
                ;;
            *)
                echo -e "${RED}Please answer y or n.${NC}"
                ;;
        esac
    done
}

# Function to get X-UI credentials
get_xui_credentials() {
    while true; do
        read -p "Do you want to configure 3x-ui? (y/n): " CONFIG_XUI
        case $CONFIG_XUI in
            [Yy]*)
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
                break
                ;;
            [Nn]*)
                echo -e "${GREEN}Skipping 3x-ui configuration...${NC}"
                break
                ;;
            *)
                echo -e "${RED}Please answer y or n.${NC}"
                ;;
        esac
    done
}

# Function to get Psiphon configuration
get_psiphon_config() {
    while true; do
        read -p "Do you want to configure Psiphon? (y/n): " CONFIG_PSIPHON
        case $CONFIG_PSIPHON in
            [Yy]*)
                break
                ;;
            [Nn]*)
                echo -e "${GREEN}Skipping Psiphon configuration...${NC}"
                break
                ;;
            *)
                echo -e "${RED}Please answer y or n.${NC}"
                ;;
        esac
    done
}

# Function to set timezone
set_timezone() {
    echo -e "${GREEN}Setting Timezone to Asia/Tehran...${NC}"
    sudo timedatectl set-timezone Asia/Tehran
    echo -e "${GREEN}Timezone Set For Tehran/Asia${NC}"
}

# Function to install Certbot
install_certbot() {
    check_existing_certs
    get_common_info
    if [ -z "$USE_EXISTING_CERT" ] || [ "$USE_EXISTING_CERT" = "n" ]; then
        echo -e "${GREEN}Installing Certbot and obtaining SSL certificates...${NC}"
        apt-get install certbot -y
        mkdir -p "/root/cert/$CERTBOT_DOMAIN"
        certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$CERTBOT_DOMAIN"
        certbot renew --dry-run

        echo -e "${GREEN}Creating certificate symlinks...${NC}"
        ln -s "/etc/letsencrypt/live/$CERTBOT_DOMAIN/fullchain.pem" "/root/cert/$CERTBOT_DOMAIN/fullchain.pem"
        ln -s "/etc/letsencrypt/live/$CERTBOT_DOMAIN/privkey.pem" "/root/cert/$CERTBOT_DOMAIN/privkey.pem"
        echo -e "${GREEN}Created certificate symlinks...${NC}"
    else
        echo -e "${GREEN}Using existing certificate for $CERTBOT_DOMAIN${NC}"
        mkdir -p "/root/cert/$CERTBOT_DOMAIN"
        ln -s "/etc/letsencrypt/live/$CERTBOT_DOMAIN/fullchain.pem" "/root/cert/$CERTBOT_DOMAIN/fullchain.pem"
        ln -s "/etc/letsencrypt/live/$CERTBOT_DOMAIN/privkey.pem" "/root/cert/$CERTBOT_DOMAIN/privkey.pem"
        echo -e "${GREEN}Created certificate symlinks for existing certificate...${NC}"
    fi
}

# Function to configure DNS
configure_dns() {
    get_dns_info
    if [ "$CONFIG_DNS" = "y" ]; then
        echo -e "${GREEN}Changing DNS Settings...${NC}"
        sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak

        sudo bash -c "cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=$IPV4
EOF"

        sudo systemctl restart systemd-resolved
        echo -e "${GREEN}resolved.conf has been updated and the service has been restarted.${NC}"
        echo -e "${GREEN}A backup of the original file was saved as /etc/systemd/resolved.conf.bak${NC}"
    fi
}

# Function to install AdGuard Home
install_adguard_home() {
    get_agh_credentials
    if [ "$CONFIG_AGH" = "y" ]; then
        check_existing_certs
        get_common_info
        echo -e "${GREEN}Running AdGuard home installation script...${NC}"
        curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

        echo -e "${GREEN}Configuring AdGuard home settings${NC}"
        sudo mkdir -p "/root/cert/$CERTBOT_DOMAIN"
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
  certificate_path: /root/cert/$CERTBOT_DOMAIN/fullchain.pem
  private_key_path: /root/cert/$CERTBOT_DOMAIN/privkey.pem
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

        sudo systemctl restart AdGuardHome
        echo -e "${GREEN}AdGuardHome.yaml has been updated and the service has been restarted.${NC}"
        echo -e "${GREEN}Admin credentials:${NC}"
        echo -e "${GREEN}Username: $AGH_USERNAME${NC}"
        echo -e "${GREEN}Password: ********${NC}"
    fi
}

# Function to install 3x-ui
install_3xui() {
    get_xui_credentials
    if [ "$CONFIG_XUI" = "y" ]; then
        check_existing_certs
        get_common_info
        echo -e "${GREEN}Running 3x-ui installation script...${NC}"
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
        {
            sleep 2; echo "18"
            sleep 2; echo "5"
            sleep 2; echo "$CERTBOT_DOMAIN"
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
    fi
}

# Function to install and configure Psiphon
install_psiphon() {
    get_psiphon_config
    if [ "$CONFIG_PSIPHON" = "y" ]; then
        echo -e "${GREEN}Installing Psiphon...${NC}"
        
        # Install required packages
        if ! command -v wget &> /dev/null; then
            echo -e "${GREEN}Installing wget...${NC}"
            apt-get install -y wget
        fi

        # Download and run Psiphon installation script
        echo -e "${GREEN}Downloading Psiphon installation script...${NC}"
        wget https://raw.githubusercontent.com/SpherionOS/PsiphonLinux/main/plinstaller2 -O plinstaller2
        chmod +x plinstaller2
        sudo sh plinstaller2
        rm plinstaller2

        # Create Psiphon systemd service
        echo -e "${GREEN}Creating Psiphon systemd service...${NC}"
        cat > /etc/systemd/system/psiphon.service <<EOF
[Unit]
Description=Psiphon Service
After=network-online.target

[Service]
Type=simple
ExecStart=/etc/psiphon/psiphon-tunnel-core-x86_64 -config /etc/psiphon/psiphon.config
StandardOutput=append:/var/log/psiphon.log
StandardError=append:/var/log/psiphon.log
Restart=always
User=root
Group=root
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
EOF

        # Reload systemd and start Psiphon service
        sudo systemctl daemon-reload
        sudo systemctl enable psiphon.service
        sudo systemctl start psiphon.service
        echo -e "${GREEN}Psiphon service has been configured and started.${NC}"
    fi
}

# Function to configure Backhaul
configure_backhaul() {
    get_backhaul_config
    if [ "$CONFIG_BACKHAUL" = "y" ]; then
        echo -e "${GREEN}Configuring Backhaul...${NC}"
        
        # Install required packages
        if ! command -v unzip &> /dev/null; then
            echo -e "${GREEN}Installing unzip...${NC}"
            apt-get install -y unzip
        fi
        if ! command -v wget &> /dev/null; then
            echo -e "${GREEN}Installing wget...${NC}"
            apt-get install -y wget
        fi

        # Create directories and download Backhaul
        mkdir -p /root/backhaul/B
        cd /root/backhaul
        echo -e "${GREEN}Downloading Backhaul...${NC}"
        if [ "$SERVER_TYPE" = "d" ]; then
            wget https://orioni.ir/Backhaul/ir-B.zip
        else
            wget https://orioni.ir/Backhaul/kh-B.zip
        fi
        unzip *-B.zip
        rm *-B.zip

        # Set permissions
        chmod +x /root/backhaul/B/B
        chmod +x /root/backhaul/B/E.sh

        # Configure config.toml
        echo -e "${GREEN}Configuring Backhaul config.toml...${NC}"
        cat > /root/backhaul/B/config.toml <<EOF
[client]
remote_addr = "$BACKHAUL_DOMAIN:$BACKHAUL_PORT"
edge_ip = ""
transport = "ws"
token = "$BACKHAUL_TOKEN"
connection_pool = 8
aggressive_pool = false
keepalive_period = 75
dial_timeout = 10
retry_interval = 3
nodelay = true
log_level = "info"
EOF

        # Create B.service
        echo -e "${GREEN}Creating B.service...${NC}"
        cat > /etc/systemd/system/B.service <<EOF
[Unit]
Description=Backhaul Reverse Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/root/backhaul/B/B -c /root/backhaul/B/config.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

        # Create E.service
        echo -e "${GREEN}Creating E.service...${NC}"
        cat > /etc/systemd/system/E.service <<EOF
[Unit]
Description=Backhaul Service Monitor
After=network.target B.service

[Service]
ExecStart=/root/backhaul/B/E.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

        # Reload systemd
        sudo systemctl daemon-reload
        echo -e "${GREEN}Systemd daemon reloaded.${NC}"
    fi
}

# Function to disable ICMP
disable_icmp() {
    echo -e "${GREEN}Disabling ICMP Echo Requests...${NC}"
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
    sudo bash -c 'cat >> /etc/sysctl.conf <<EOF
# Disable ping (ICMP Echo Request replies)
net.ipv4.icmp_echo_ignore_all = 1
EOF'
    sudo sysctl -p
    echo -e "${GREEN}ICMP Echo Requests disabled.${NC}"
}

# Function for domestic server setup
domestic_server_setup() {
    echo -e "${GREEN}Starting Domestic Server Setup...${NC}"
    check_existing_certs
    get_common_info
    get_backhaul_config
    install_certbot
    configure_backhaul
    disable_icmp
    echo -e "${GREEN}Domestic server setup completed!${NC}"
}

# Function for foreign server setup
foreign_server_setup() {
    echo -e "${GREEN}Starting Foreign Server Setup...${NC}"
    check_existing_certs
    get_common_info
    get_dns_info
    get_agh_credentials
    get_backhaul_config
    get_xui_credentials
    get_psiphon_config
    set_timezone
    if [ "$CONFIG_XUI" = "y" ] || [ "$CONFIG_AGH" = "y" ]; then
        install_certbot
    fi
    if [ "$CONFIG_AGH" = "y" ]; then
        install_adguard_home
    fi
    if [ "$CONFIG_DNS" = "y" ]; then
        configure_dns
    fi
    if [ "$CONFIG_XUI" = "y" ]; then
        install_3xui
    fi
    if [ "$CONFIG_BACKHAUL" = "y" ]; then
        configure_backhaul
    fi
    if [ "$CONFIG_PSIPHON" = "y" ]; then
        install_psiphon
    fi
    echo -e "${GREEN}Foreign server setup completed!${NC}"
}

# Main script
echo -e "${GREEN}VPN Server Setup Script${NC}"

# Ask for system update
while true; do
    read -p "Do you want to update the system? (y/n): " UPDATE_SYSTEM
    case $UPDATE_SYSTEM in
        [Yy]*)
            echo -e "${GREEN}Updating system...${NC}"
            sudo apt-get update && sudo apt-get upgrade -y
            break
            ;;
        [Nn]*)
            echo -e "${GREEN}Skipping system update...${NC}"
            break
            ;;
        *)
            echo -e "${RED}Please answer y or n.${NC}"
            ;;
    esac
done

# Main menu loop
while true; do
    show_main_menu
    read -p "Enter your choice (0-3): " MAIN_CHOICE
    case $MAIN_CHOICE in
        1)
            SERVER_TYPE="d"
            domestic_server_setup
            ;;
        2)
            SERVER_TYPE="f"
            foreign_server_setup
            ;;
        3)
            while true; do
                show_package_menu
                read -p "Enter your choice (0-8): " PACKAGE_CHOICE
                case $PACKAGE_CHOICE in
                    1)
                        set_timezone
                        ;;
                    2)
                        install_certbot
                        ;;
                    3)
                        configure_dns
                        ;;
                    4)
                        install_adguard_home
                        ;;
                    5)
                        install_3xui
                        ;;
                    6)
                        configure_backhaul
                        ;;
                    7)
                        disable_icmp
                        ;;
                    8)
                        install_psiphon
                        ;;
                    0)
                        break
                        ;;
                    *)
                        echo -e "${RED}Invalid choice. Please select 0-8.${NC}"
                        ;;
                esac
                read -p "Press Enter to continue..."
            done
            ;;
        0)
            echo -e "${GREEN}Exiting script...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select 0-3.${NC}"
            ;;
    esac
done
