#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

cd "$TERRAFORM_DIR"

if [ ! -f "terraform.tfstate" ]; then
    echo "No Terraform state found. Nothing to destroy."
    exit 0
fi

ACR_NAME=$(terraform output -raw acr_name 2>/dev/null || echo "Unknown")
CLIENT_ID=$(grep "^client_id" terraform.tfvars 2>/dev/null | cut -d'=' -f2 | tr -d ' "' || echo "")

echo ""
echo "WARNING: This will destroy:"
echo "  - ACR: $ACR_NAME"
echo "  - Service Principal: $CLIENT_ID"
echo "  - All container images and repositories"
echo "  - All local files and credentials"
echo ""
read -p "Type 'destroy' to confirm: " CONFIRM

if [ "$CONFIRM" != "destroy" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "Destroying ACR..."
terraform destroy -auto-approve

echo "Deleting Service Principal..."
if [ -n "$CLIENT_ID" ]; then
    az ad sp delete --id "$CLIENT_ID" 2>/dev/null || echo "Service Principal already deleted or not found"
fi

echo "Cleaning up local files..."
rm -f terraform.tfstate terraform.tfstate.backup terraform.tfvars
rm -rf .terraform .terraform.lock.hcl
rm -f ../acr-credentials.txt

echo ""
echo "✓ Complete destruction finished"
echo "Everything removed. Run ./scripts/create-sp.sh to start fresh"
