#!/bin/bash
set -e

echo "Create Service Principal for ACR"
echo "================================="
echo ""

if ! az account show > /dev/null 2>&1; then
    echo "ERROR: Not authenticated. Run: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription: $(az account show --query name -o tsv)"
echo ""

read -p "Service Principal name [acr-terraform]: " SP_NAME
SP_NAME=${SP_NAME:-acr-terraform}

echo "Creating Service Principal..."

SP=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role Contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --output json)

CLIENT_ID=$(echo "$SP" | grep -o '"appId": "[^"]*"' | cut -d'"' -f4)
CLIENT_SECRET=$(echo "$SP" | grep -o '"password": "[^"]*"' | cut -d'"' -f4)

echo ""
echo "✓ Service Principal created"
echo ""
echo "Add to terraform.tfvars:"
echo ""
echo "client_id       = \"$CLIENT_ID\""
echo "client_secret   = \"$CLIENT_SECRET\""
echo "tenant_id       = \"$TENANT_ID\""
echo "subscription_id = \"$SUBSCRIPTION_ID\""
echo ""
