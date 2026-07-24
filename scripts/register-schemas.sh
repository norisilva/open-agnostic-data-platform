#!/bin/bash
set -e

BASE_URL="http://localhost:8081/apis/registry/v3"
GROUP_ID="renegotiation"

echo "Waiting for Apicurio Registry at $BASE_URL..."
READY=false
for i in {1..30}; do
    if curl -s -f -o /dev/null "$BASE_URL/system/info"; then
        READY=true
        break
    fi
    sleep 2
done

if [ "$READY" = false ]; then
    echo "Apicurio Registry is not ready. Exiting."
    exit 1
fi

echo "Apicurio Registry is up! Registering schemas..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SCHEMAS_DIR="$SCRIPT_DIR/../schemas/renegotiation"

# Create group if not exists (Apicurio 3.x requires explicitly creating the group)
curl -s -X POST "$BASE_URL/groups" \
  -H "Content-Type: application/json" \
  -d "{\"groupId\": \"$GROUP_ID\", \"description\": \"Renegotiation schemas\"}" > /dev/null || echo "Group might already exist"

SCHEMAS=("payment-received" "payment-validated" "receipt-generated" "receipt-failed" "notification-sent")

for SCHEMA in "${SCHEMAS[@]}"; do
    FILE_PATH="$SCHEMAS_DIR/$SCHEMA.json"
    
    echo "Registering $SCHEMA..."
    curl -s -X POST "$BASE_URL/groups/$GROUP_ID/artifacts" \
        -H "Content-Type: application/json" \
        -H "X-Registry-ArtifactId: $SCHEMA" \
        -H "X-Registry-ArtifactType: JSON" \
        -d @"$FILE_PATH" > /dev/null
    
    echo "Successfully registered $SCHEMA"
done
