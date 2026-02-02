#!/bin/bash
# ACR Info - List repositories, images, and tags

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
ACR Info - List registry contents

Usage:
  ./scripts/acr-info.sh [command] [options]

Commands:
  repos              List all repositories
  tags <repo>        List tags for a repository
  images <repo>      Show image details for a repository
  all                Show everything (repos, tags, images)

Options:
  -r, --registry     Registry name (auto-detected from tfvars if not provided)
  -h, --help         Show this help

Examples:
  ./scripts/acr-info.sh repos
  ./scripts/acr-info.sh tags myapp
  ./scripts/acr-info.sh images myapp/backend
  ./scripts/acr-info.sh all
  ./scripts/acr-info.sh repos --registry dedeeacr
EOF
}

# Get registry name from tfvars or command line
get_registry_name() {
    if [ -n "$REGISTRY_ARG" ]; then
        echo "$REGISTRY_ARG"
    elif [ -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        grep "^registry_name" "$TERRAFORM_DIR/terraform.tfvars" | cut -d'=' -f2 | tr -d ' "'
    else
        echo ""
    fi
}

list_repos() {
    local registry="$1"
    echo -e "${BLUE}Repositories in $registry:${NC}"
    echo ""
    az acr repository list --name "$registry" --output table
}

list_tags() {
    local registry="$1"
    local repo="$2"
    echo -e "${BLUE}Tags for $registry/$repo:${NC}"
    echo ""
    az acr repository show-tags --name "$registry" --repository "$repo" --output table
}

show_images() {
    local registry="$1"
    local repo="$2"
    echo -e "${BLUE}Images for $registry/$repo:${NC}"
    echo ""
    az acr manifest list-metadata --registry "$registry" --name "$repo" --output table
}

show_all() {
    local registry="$1"
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}ACR Contents: $registry${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo ""
    
    list_repos "$registry"
    echo ""
    
    # Get all repos
    repos=$(az acr repository list --name "$registry" --output tsv 2>/dev/null || echo "")
    
    if [ -z "$repos" ]; then
        echo -e "${YELLOW}No repositories found${NC}"
        return
    fi
    
    # For each repo, show tags
    while IFS= read -r repo; do
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        list_tags "$registry" "$repo"
    done <<< "$repos"
    
    echo ""
    echo -e "${GREEN}==================================================${NC}"
}

# Parse arguments
COMMAND=""
REPO_ARG=""
REGISTRY_ARG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        repos|tags|images|all)
            COMMAND="$1"
            shift
            ;;
        -r|--registry)
            REGISTRY_ARG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [ -z "$REPO_ARG" ]; then
                REPO_ARG="$1"
            fi
            shift
            ;;
    esac
done

# Get registry name
REGISTRY=$(get_registry_name)

if [ -z "$REGISTRY" ]; then
    echo "Error: Registry name not found"
    echo "Specify with --registry or ensure terraform.tfvars exists"
    exit 1
fi

# Execute command
case "$COMMAND" in
    repos)
        list_repos "$REGISTRY"
        ;;
    tags)
        if [ -z "$REPO_ARG" ]; then
            echo "Error: Repository name required"
            echo "Usage: ./scripts/acr-info.sh tags <repo-name>"
            exit 1
        fi
        list_tags "$REGISTRY" "$REPO_ARG"
        ;;
    images)
        if [ -z "$REPO_ARG" ]; then
            echo "Error: Repository name required"
            echo "Usage: ./scripts/acr-info.sh images <repo-name>"
            exit 1
        fi
        show_images "$REGISTRY" "$REPO_ARG"
        ;;
    all)
        show_all "$REGISTRY"
        ;;
    "")
        echo "Error: Command required"
        echo ""
        show_help
        exit 1
        ;;
    *)
        echo "Error: Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
