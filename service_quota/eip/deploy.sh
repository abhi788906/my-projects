#!/bin/bash

# =============================================================================
# Elastic IP Monitoring Infrastructure - Deployment Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="elastic-ip-monitor"
ENVIRONMENT="${ENVIRONMENT:-production}"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check Terraform version
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log "Terraform version: $TF_VERSION"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI is not installed. Please ensure AWS credentials are configured."
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Please install jq for JSON processing."
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

# Validate configuration
validate_config() {
    log "Validating configuration..."
    
    if [[ ! -f "$SCRIPT_DIR/config.json" ]]; then
        log_error "Configuration file config.json not found"
        exit 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$SCRIPT_DIR/config.json" 2>/dev/null; then
        log_error "Invalid JSON in config.json"
        exit 1
    fi
    
    # Check required fields
    local required_fields=("project_name" "environment" "aws_region")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$SCRIPT_DIR/config.json" >/dev/null 2>&1; then
            log_error "Required field '$field' missing in config.json"
            exit 1
        fi
    done
    
    log_success "Configuration validation completed"
}

# Build Lambda layer
build_lambda_layer() {
    log "Building Lambda layer..."
    
    local layer_dir="$SCRIPT_DIR/../lambda-layer"
    if [[ ! -d "$layer_dir" ]]; then
        log_error "Lambda layer directory not found: $layer_dir"
        exit 1
    fi
    
    cd "$layer_dir"
    
    if [[ ! -f "build_layer.sh" ]]; then
        log_error "build_layer.sh script not found in lambda-layer directory"
        exit 1
    fi
    
    # Make script executable and run it
    chmod +x build_layer.sh
    ./build_layer.sh
    
    if [[ ! -f "build/elastic-ip-monitor-layer.zip" ]]; then
        log_error "Failed to build Lambda layer"
        exit 1
    fi
    
    log_success "Lambda layer built successfully"
    cd "$SCRIPT_DIR"
}

# Build Lambda function
build_lambda_function() {
    log "Building Lambda function..."
    
    local function_dir="$SCRIPT_DIR/.."
    local function_file="$function_dir/lambda_function.py"
    
    if [[ ! -f "$function_file" ]]; then
        log_error "Lambda function file not found: $function_file"
        exit 1
    fi
    
    cd "$function_dir"
    
    # Create a temporary directory for the function
    local temp_dir=$(mktemp -d)
    cp lambda_function.py "$temp_dir/"
    
    # Create ZIP file
    cd "$temp_dir"
    zip -r lambda_function.zip lambda_function.py >/dev/null
    
    # Move ZIP to project directory
    mv lambda_function.zip "$SCRIPT_DIR/../lambda_function.zip"
    
    # Cleanup
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    log_success "Lambda function built successfully"
}

# Initialize Terraform
init_terraform() {
    log "Initializing Terraform..."
    
    cd "$SCRIPT_DIR"
    
    # Initialize Terraform
    terraform init -upgrade
    
    log_success "Terraform initialization completed"
}

# Plan Terraform deployment
plan_terraform() {
    log "Planning Terraform deployment..."
    
    cd "$SCRIPT_DIR"
    
    # Create plan file
    terraform plan -out=tfplan
    
    log_success "Terraform plan created"
}

# Deploy infrastructure
deploy_infrastructure() {
    log "Deploying infrastructure..."
    
    cd "$SCRIPT_DIR"
    
    # Apply Terraform plan
    terraform apply tfplan
    
    log_success "Infrastructure deployment completed"
}

# Show outputs
show_outputs() {
    log "Infrastructure outputs:"
    terraform output -json | jq '.'
}

# Main deployment function
main() {
    log "Starting deployment of $PROJECT_NAME infrastructure..."
    log "Environment: $ENVIRONMENT"
    log "Script directory: $SCRIPT_DIR"
    
    # Check prerequisites
    check_prerequisites
    
    # Validate configuration
    validate_config
    
    # Build Lambda components
    build_lambda_layer
    build_lambda_function
    
    # Initialize Terraform
    init_terraform
    
    # Plan deployment
    plan_terraform
    
    # Ask for confirmation
    echo
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Deploy infrastructure
        deploy_infrastructure
        
        # Show outputs
        show_outputs
        
        log_success "Deployment completed successfully!"
    else
        log_warning "Deployment cancelled by user"
        exit 0
    fi
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
