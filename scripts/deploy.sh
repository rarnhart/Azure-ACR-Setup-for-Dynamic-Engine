#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
CRED_FILE="${SCRIPT_DIR}/../acr-credentials.txt"

cd "$TERRAFORM_DIR"

if [ ! -d ".terraform" ]; then
    echo "ERROR: Terraform not initialized. Run ./scripts/init.sh first"
    exit 1
fi

echo "Deploying Azure Container Registry..."
echo ""

terraform apply

echo ""
echo "=========================================="
echo "Getting Registry Information"
echo "=========================================="

ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)

echo "Registry: $ACR_NAME"
echo "URL: $ACR_LOGIN_SERVER"
echo ""

# Get admin credentials
CLIENT_ID=$(grep "^client_id" terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
CLIENT_SECRET=$(grep "^client_secret" terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
TENANT_ID=$(grep "^tenant_id" terraform.tfvars | cut -d'=' -f2 | tr -d ' "')

echo "Authenticating..."
az login --service-principal \
    --username "$CLIENT_ID" \
    --password="$CLIENT_SECRET" \
    --tenant "$TENANT_ID" > /dev/null 2>&1

echo "Retrieving credentials..."
CREDS=$(az acr credential show --name "$ACR_NAME" --output json)

USERNAME=$(echo "$CREDS" | grep -o '"username": "[^"]*"' | cut -d'"' -f4)
PASSWORD=$(echo "$CREDS" | grep -o '"value": "[^"]*"' | head -1 | cut -d'"' -f4)
PASSWORD2=$(echo "$CREDS" | grep -o '"value": "[^"]*"' | tail -1 | cut -d'"' -f4)

echo ""
echo "=========================================="
echo "CREDENTIALS"
echo "=========================================="
echo ""
echo "Registry URL: $ACR_LOGIN_SERVER"
echo "Username:     $USERNAME"
echo "Password:     $PASSWORD"
echo ""

# Save to file
cat > "$CRED_FILE" << EOF
Azure Container Registry Credentials
=====================================

Registry URL:  $ACR_LOGIN_SERVER
Path:          <repo-name>
Username:      $USERNAME
Password:      $PASSWORD
Password2:     $PASSWORD2

Docker Login:
  docker login $ACR_LOGIN_SERVER -u $USERNAME -p $PASSWORD

Docker Push:
  docker tag myimage:latest $ACR_LOGIN_SERVER/myapp:latest
  docker push $ACR_LOGIN_SERVER/myapp:latest

IDE Config:
  Registry: $ACR_LOGIN_SERVER
  Path:     myapp
  Username: $USERNAME
  Password: $PASSWORD
EOF

echo "✓ Credentials saved to: acr-credentials.txt"
echo ""
echo "✓ Deployment complete"
