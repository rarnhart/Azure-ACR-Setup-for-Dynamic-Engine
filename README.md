# Azure Container Registry for Dynamic Engine Quick Setup

Simplified Terraform package for standing up Azure Container Registry for demonstration purposes.

## Quick Start (5 minutes)

```bash
# 1. Create Service Principal (one-time)
az login
./scripts/create-sp.sh
# Copy the output credentials

# 2. Configure
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit: paste credentials, set registry name

# 3. Deploy
cd ..
./scripts/init.sh
./scripts/deploy.sh
# Credentials saved to acr-credentials.txt

# 4. View registry contents
./scripts/acr-info.sh all

# 5. Use (see acr-credentials.txt for details)
docker login <registry-url> -u <username> -p <password>
docker push <registry-url>/myapp:latest

# 6. Complete teardown
./scripts/destroy.sh
# Type 'destroy' to confirm
```

## What Gets Created

- Azure Container Registry (Basic tier, ~$0.167/day)
- Service Principal with Contributor role
- Resource group
- Credentials file: `acr-credentials.txt`

## What Gets Destroyed

Everything. Zero remnants:
- ACR and all container images
- All repositories
- Service Principal
- Resource group
- terraform.tfstate
- terraform.tfvars
- acr-credentials.txt

Clean slate every time.

## Scripts

### Core Workflow
- `create-sp.sh` - Create Service Principal (one-time setup)
- `init.sh` - Initialize Terraform
- `deploy.sh` - Deploy ACR, generate credentials file
- `destroy.sh` - Complete teardown (requires typing 'destroy')

### Convenience Tools
- `acr-info.sh` - List repositories, images, and tags

## ACR Info Script

View your registry contents without Docker:

```bash
# List all repositories
./scripts/acr-info.sh repos

# List tags for a repository
./scripts/acr-info.sh tags myapp

# Show image details
./scripts/acr-info.sh images myapp/backend

# Show everything
./scripts/acr-info.sh all

# Use different registry
./scripts/acr-info.sh repos --registry otherregistry
```

## Credentials File

After deployment, `acr-credentials.txt` contains:
- Registry URL (e.g., `myacr.azurecr.io`)
- Username
- Password (two passwords for rotation)
- Docker commands (login, push, pull)
- IDE configuration

Share this file with your team.

## Docker Login (Recommended Method)

```bash
# Using password-stdin (recommended)
echo "<password>" | docker login myacr.azurecr.io -u myacr --password-stdin

# Or get password dynamically
az acr credential show --name myacr --query "passwords[0].value" -o tsv | \
  docker login myacr.azurecr.io -u myacr --password-stdin
```

## Registry Naming

- Must be globally unique across all Azure
- 5-50 characters
- Alphanumeric only (no hyphens, underscores, or special characters)
- Examples: `mycompanyacr`, `myacr`, `acrdemo123`

## Repository Organization

Repositories support hierarchical paths:

```
myacr.azurecr.io/myapp:latest              # Flat
myacr.azurecr.io/frontend/web:v1.0         # Two levels
myacr.azurecr.io/company/team/service:tag  # Three levels
```

Repositories are created automatically on first push.

## Notes

- Docker daemon must be running for `docker login` and push/pull
- Use `az acr` commands to manage registry without Docker
- Service Principal has Contributor role at subscription level
- Admin credentials enabled by default for easy IDE integration
- Use `acr-info.sh` to browse contents without pulling images

## Troubleshooting

**Registry name not available:**
- Name must be globally unique
- Try adding numbers or company identifier

**Docker daemon not running:**
- macOS: Open Docker Desktop
- Linux: `sudo systemctl start docker`

**"Cannot connect" errors:**
- Verify authentication: `az acr credential show --name <registry>`
- Check Docker is running: `docker info`

**After destroy, resources still exist:**
- Check: `az acr list --output table`
- Manual cleanup: `az acr delete --name <registry> --yes`
- Check Service Principal: `az ad sp list --display-name <sp-name>`
