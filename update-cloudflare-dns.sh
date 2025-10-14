#!/bin/bash

# Your Cloudflare credentials
API_TOKEN="HGtxfpkKHkuJ1y1ASnMcrs09QUSd12NAk5-DQrrE"
ZONE_ID="54f47e43cd92813e9a49af015d7c2b1e"

# List of records to update
RECORDS=("oshaw1.dev" "passman.oshaw1.dev" "nettest.oshaw1.dev" "portfolio.oshaw1.dev")

# Get current IP
CURRENT_IP=$(curl -s https://api.ipify.org)

echo "Current IP: ${CURRENT_IP}"
echo "Updating DNS records..."

# Loop through each record
for RECORD_NAME in "${RECORDS[@]}"; do
    # Get DNS record ID
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${RECORD_NAME}" \
         -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
    
    if [ -z "$RECORD_ID" ]; then
        echo "Warning: Could not find record ID for ${RECORD_NAME}"
        continue
    fi
    
    # Update the record
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
         -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Content-Type: application/json" \
         --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${CURRENT_IP}\",\"ttl\":1,\"proxied\":true}")
    
    # Check if update was successful
    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo "✓ Updated ${RECORD_NAME} to ${CURRENT_IP}"
    else
        echo "✗ Failed to update ${RECORD_NAME}"
    fi
done

echo "DNS update complete!"
