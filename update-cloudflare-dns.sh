#!/bin/bash
if [ -f .cloudflareenv ]; then
    export $(cat .cloudflareenv | grep -v '^#' | xargs)
else
    echo "Error: .cloudflareenv file not found"
    exit 1
fi

# Your Cloudflare credentials
API_TOKEN="${CLOUDFLARE_API_TOKEN}"
ZONE_ID="${CLOUDFLARE_ZONE_ID}"
echo "Detected api token: ${API_TOKEN}"
echo "Detected zone ID: ${ZONE_ID}"

# List of records to update
IFS=',' read -ra RECORDS <<< "${DNS_RECORDS}"
echo "Number of records detected: ${#RECORDS[@]}"
echo "All records:"
for i in "${!RECORDS[@]}"; do
    echo "  [$i]: '${RECORDS[$i]}'"
done

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
