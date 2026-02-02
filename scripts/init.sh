#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

cd "$TERRAFORM_DIR"

if [ ! -f "terraform.tfvars" ]; then
    echo "ERROR: terraform.tfvars not found"
    echo "Copy terraform.tfvars.example to terraform.tfvars and configure it"
    exit 1
fi

echo "Initializing Terraform..."
terraform init -upgrade

echo "✓ Terraform initialized"
echo "Next: ./scripts/deploy.sh"
