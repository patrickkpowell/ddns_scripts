#!/bin/bash

CONFIG_FILE="/etc/cloudflare.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"
CURRENT_IP=$(curl -s http://ipv4.icanhazip.com)

# Check if the DNS record exists
RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$HOSTNAME" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Content-Type: application/json")

if echo "$RECORD" | grep -q '"success":true' && [ "$(echo "$RECORD" | jq -r '.result | length')" -eq 0 ]; then
    echo "Record does not exist. Creating a new DNS record."
    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$HOSTNAME\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXIED}")

else
    RECORD_ID=$(echo "$RECORD" | jq -r '.result[0].id')
    echo "Updating existing DNS record with ID: $RECORD_ID"
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$HOSTNAME\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":$PROXIED}")
fi

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "DNS record updated successfully."
else
    echo "Failed to update DNS record. Response: $RESPONSE"
    exit 1
fi

