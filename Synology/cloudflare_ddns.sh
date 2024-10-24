#!/bin/bash

# Default config file path (can be overridden with --config)
CONFIG_FILE=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --config <path_to_config_file>"
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --config) CONFIG_FILE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Ensure the config file is provided
if [ -z "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not specified."
    usage
fi

# Ensure the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Load configuration variables from the config file
source "$CONFIG_FILE"

# Fetch the current public IP address
CURRENT_IP=$(curl -s http://ipv4.icanhazip.com)

# Update the DNS record via Cloudflare API
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$HOSTNAME\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXIED}")

# Check the response for success
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "DNS record updated successfully. IP: $CURRENT_IP"
else
    echo "Failed to update DNS record. Response: $RESPONSE"
    exit 1
fi

