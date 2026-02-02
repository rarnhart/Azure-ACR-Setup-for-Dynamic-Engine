# Quick Start Guide

## Setup (5 minutes)

```bash
# 1. Authenticate
az login

# 2. Create Service Principal
./scripts/create-sp.sh
# Note the credentials output

# 3. Configure
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars:
#   - Paste SP credentials from step 2
#   - Set registry_name (e.g., "mycompanyacr")
cd ..

# 4. Initialize and Deploy
./scripts/init.sh
./scripts/deploy.sh
```

## Use

Credentials are in `acr-credentials.txt`. Use them to:

```bash
# Login
docker login dedeeacr.azurecr.io -u dedeeacr -p <password>

# Push
docker tag myapp:latest dedeeacr.azurecr.io/myapp:latest
docker push dedeeacr.azurecr.io/myapp:latest

# View contents
./scripts/acr-info.sh all
```

## Teardown

```bash
./scripts/destroy.sh
# Type 'destroy' to confirm
```

Removes everything: ACR, images, Service Principal, all files.
