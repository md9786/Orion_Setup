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
    echo "║ 1. Foreign Server Setup                    ║"
    echo "║ 0. Exit                                    ║"
    echo "╚════════════════════════════════════════════╝"
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

# Function to get foreign server information
get_foreign_info() {
    get_common_info
    get_agh_credentials
    
    # Confirm settings
    echo -e "${GREEN}"
    echo "Configuration Summary:"
    echo "Domain: $DOMAIN"
    echo "AdGuard Home Username: $AGH_USERNAME"
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

# Function to install AdGuard Home
install_adguard_home() {
    if [ -z "$AGH_USERNAME" ] || [ -z "$AGH_PASSWORD_HASH" ]; then
        get_agh_credentials
    fi
    
    if [ -z "$DOMAIN" ]; then
        get_common_info
    fi
    
    echo -e "${GREEN}Running AdGuard home installation script...${NC}"
    curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

    echo -e "${GREEN}Configuring AdGuard home settings...${NC}"
    sudo mkdir -p "/root/cert/$DOMAIN"
    echo -e "${YELLOW}Note: Please copy your local SSL certs to: /root/cert/$DOMAIN/fullchain.pem and /root/cert/$DOMAIN/privkey.pem${NC}"
    sudo cp /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml.bak

    # Create a temporary file for AdGuard configuration
    TMP_AGH_CONF=$(mktemp)
    cat > "$TMP_AGH_CONF" <<EOF
http:
  pprof:
    port: 6060
    enabled: false
  doh:
    routes:
      - GET /dns-query
      - POST /dns-query
      - GET /dns-query/{ClientID}
      - POST /dns-query/{ClientID}
    insecure_enabled: false
  address: 0.0.0.0:4200
  session_ttl: 30d
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
    - trk.pinterest.com
    - mobile.events.data.microsoft.com
    - locationhistory-pa.googleapis.com
    - firebaselogging.googleapis.com
    - jarlio-launches.appsflyersdk.com
    - prod-mediate-events.applovin.com
    - etahub.com
    - googleads.g.doubleclick.net
    - reqhfg-launches.appsflyersdk.com
    - mobile.pipe.aria.microsoft.com
    - teams.events.data.microsoft.com
    - receiver.habby.mobi
    - mqtt-gw.pushnotifs.com
    - firebaselogging-pa.googleapis.com
    - o-sdk.mediation.unity3d.com
    - jarlio-inapps.appsflyersdk.com
    - api-apac.bidmachine.io
    - app-analytics-services.com
    - app-analytics-v2.snapchat.com
    - beacons.gcp.gvt2.com
    - beacons.gvt2.com
    - beacons5.gvt3.com
    - bstream.kzhi.tech
    - cdn.iads.unity3d.com
    - cdn2.inner-active.mobi
    - g.live.com
    - gamedot.afafb.com
    - graph.instagram.com
    - in.appcenter.ms
    - log16-normal-useast8.tiktokv.us
    - logs.ads.vungle.com
    - sac.presage.io
    - sdk.split.io
    - sdk-events.inner-active.mobi
    - self.events.data.microsoft.com
    - unif-id.ssp.inmobi.com
    - y.hashemi0026.example.com
    - y.hashemi0026.example.com.aeza.network
  trusted_proxies:
    - 127.0.0.0/8
    - ::1/128
  cache_enabled: true
  cache_size: 4194304
  cache_ttl_min: 0
  cache_ttl_max: 0
  cache_optimistic: false
  cache_optimistic_answer_ttl: 30s
  cache_optimistic_max_age: 12h
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
  server_name: $DOMAIN
  force_https: true
  port_https: 2095
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
  interval: 1d
  size_memory: 1000
  enabled: false
  ignored_enabled: false
  file_enabled: true
statistics:
  dir_path: ""
  ignored: []
  interval: 1d
  enabled: true
  ignored_enabled: false
filters:
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
    name: OISD Blocklist Big
    id: 1783111209
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_63.txt
    name: HaGeZi's Windows/Office Tracker Blocklist
    id: 1783111210
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt
    name: AdGuard DNS Popup Hosts filter
    id: 1783111211
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt
    name: HaGeZi's Pro++ Blocklist
    id: 1783111212
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt
    name: Perflyst and Dandelion Sprout's Smart-TV Blocklist
    id: 1783111213
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_39.txt
    name: Dandelion Sprout's Anti Push Notifications
    id: 1783111214
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_19.txt
    name: 'IRN: PersianBlocker list'
    id: 1783111215
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_57.txt
    name: ShadowWhisperer's Dating List
    id: 1783111216
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_53.txt
    name: AWAvenue Ads Rule
    id: 1783111217
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt
    name: Dan Pollock's List
    id: 1783111218
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_54.txt
    name: HaGeZi's DynDNS Blocklist
    id: 1783111219
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    id: 1783111220
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt
    name: Steven Black's List
    id: 1783111221
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
  - '@@||ccb.megafiles.store^'
  - '@@||icyhailstorm29.online^'
  - '@@||clearbluesky72.wiki^'
  - '@@||notube.cc^'
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
  - '||y.hashemi0026.example.com.aeza.network^'
  - '||y.hashemi0026.example.com^'
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
  max_http_size: 256MB
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  filters_update_interval: 24
  blocked_response_ttl: 10
  filtering_enabled: true
  rewrites_enabled: true
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
schema_version: 34
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

# Function to setup foreign server
setup_foreign_server() {
    get_foreign_info
    
    # Run all foreign server components in order
    set_timezone
    install_adguard_home
    
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

# Main script execution
while true; do
    show_main_menu
    read -p "Select an option (0-1): " choice
    
    case $choice in
        1) setup_foreign_server ;;
        0) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
    
    read -p "Press Enter to continue..."
done
