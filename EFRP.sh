#!/bin/bash

# --- Configuration ---
SERVICE_PREFIX="frpc@"
CONFIG_DIR="/root/frp/client"
ERROR_STRING="connect to server error: timeout|connect to server error: dial tcp"
LOG_FILE="/var/log/frp_monitor.log"
MAX_RESTARTS_IN_ROW=3
CHECK_INTERVAL_SECONDS=5
SCHEDULED_RESTART_INTERVAL_MINUTES=20
RESTART_STABILIZE_SLEEP=3
RESTART_WAIT_SECONDS=10

# --- Functions ---

log_message() {
    local message="$1"
    local color_reset="\033[0m"
    local color_green="\033[0;32m"
    local color_red="\033[0;31m"
    local colored_message

    # Check if the message contains "No error detected" for green, or error-related for red
    if [[ "$message" == *"No error detected"* ]]; then
        colored_message="${color_green}${message}${color_reset}"
    elif [[ "$message" == *"ERROR '*DETECTED"* || "$message" == *"Failed to restart"* || "$message" == *"Error:"* ]]; then
        colored_message="${color_red}${message}${color_reset}"
    else
        colored_message="$message" # No color for neutral messages
    fi

    # Output to terminal with color
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $colored_message"
    # Output to log file without color
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

restart_frp_service() {
    local service_name="$1"
    log_message "Initiating restart of $service_name."
    log_message "Restarting $service_name."
    sudo systemctl restart "$service_name"
    if [ $? -eq 0 ]; then
        log_message "$service_name restarted successfully."
        sleep "$RESTART_STABILIZE_SLEEP"
        return 0
    else
        log_message "Failed to restart $service_name. Check systemctl status. Error code: $?."
        return 1
    fi
}

# --- Main Script Logic ---

if ! touch "$LOG_FILE" 2>/dev/null; then
    echo "Error: Cannot create or write to log file: $LOG_FILE. Exiting."
    exit 1
fi

log_message "Starting monitoring and restart script for FRP services..."

if [ ! -d "$CONFIG_DIR" ]; then
    log_message "Error: Configuration directory $CONFIG_DIR not found! Exiting."
    echo "Error: Configuration directory $CONFIG_DIR not found! Exiting."
    exit 1
fi

declare -A restart_counts
for config_file in "$CONFIG_DIR"/*.toml; do
    if [ ! -e "$config_file" ]; then
        log_message "Error: No .toml configuration files found in $CONFIG_DIR. Exiting."
        echo "Error: No .toml configuration files found in $CONFIG_DIR. Exiting."
        exit 1
    fi
    client_name=$(basename "$config_file" .toml)
    service_name="$SERVICE_PREFIX$client_name"
    restart_counts["$service_name"]=0
done

last_scheduled_restart_time=$(date +%s)

while true; do
    current_time=$(date +%s)
    
    # Check for scheduled restart
    if (( current_time - last_scheduled_restart_time >= SCHEDULED_RESTART_INTERVAL_MINUTES * 60 )); then
        log_message "Performing scheduled restart (every $SCHEDULED_RESTART_INTERVAL_MINUTES minutes)."
        for config_file in "$CONFIG_DIR"/*.toml; do
            if [ ! -e "$config_file" ]; then
                log_message "Error: No .toml configuration files found in $CONFIG_DIR. Skipping scheduled restart."
                continue
            fi
            client_name=$(basename "$config_file" .toml)
            service_name="$SERVICE_PREFIX$client_name"
            restart_frp_service "$service_name"
            if [ $? -ne 0 ]; then
                log_message "Scheduled restart failed for $service_name. Script will continue to monitor."
            fi
            restart_counts["$service_name"]=0
        done
        last_scheduled_restart_time=$current_time
    fi

    # Check each service for errors
    for config_file in "$CONFIG_DIR"/*.toml; do
        if [ ! -e "$config_file" ]; then
            log_message "Error: No .toml configuration files found in $CONFIG_DIR. Skipping error check."
            continue
        fi
        client_name=$(basename "$config_file" .toml)
        service_name="$SERVICE_PREFIX$client_name"
        log_message "Checking for error string: '$ERROR_STRING' in $service_name logs..."

        journal_output=$(sudo journalctl -u "$service_name" --no-pager -q --since="-10 seconds")
        log_message "journalctl output for $service_name: $journal_output"
        if echo "$journal_output" | grep -q "$ERROR_STRING"; then
            log_message "ERROR '$ERROR_STRING' DETECTED in $service_name logs!"

            if [ "${restart_counts["$service_name"]}" -gt "$MAX_RESTARTS_IN_ROW" ]; then
                log_message "Maximum consecutive error-based restarts ($MAX_RESTARTS_IN_ROW) reached for $service_name. Waiting $RESTART_WAIT_SECONDS seconds before retrying."
                sleep "$RESTART_WAIT_SECONDS"
                restart_counts["$service_name"]=0
            fi

            restart_counts["$service_name"]=$((restart_counts["$service_name"] + 1))
            log_message "Error-based restart attempt #${restart_counts["$service_name"]} for $service_name."

            restart_frp_service "$service_name"
            if [ $? -ne 0 ]; then
                log_message "Error-based restart failed for $service_name. Continuing to monitor other services."
            fi
        else
            if [ "${restart_counts["$service_name"]}" -gt 0 ]; then
                log_message "No error detected in the last check for $service_name. Resetting consecutive error-based restart count."
            fi
            restart_counts["$service_name"]=0
            log_message "No error detected. $service_name appears to be running normally."
        fi
    done

    sleep "$CHECK_INTERVAL_SECONDS"
done
