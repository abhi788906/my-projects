#!/bin/bash

# 🚀 Video Upload Platform Deployment Script
# This script deploys the complete infrastructure to AWS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    if ! terraform validate; then
        print_error "Terraform validation failed!"
        exit 1
    fi
    
    print_success "Terraform configuration is valid!"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    if ! terraform init; then
        print_error "Terraform initialization failed!"
        exit 1
    fi
    
    print_success "Terraform initialized successfully!"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    if ! terraform plan -out=tfplan; then
        print_error "Terraform plan failed!"
        exit 1
    fi
    
    print_success "Terraform plan created successfully!"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    
    if ! terraform apply tfplan; then
        print_error "Terraform apply failed!"
        exit 1
    fi
    
    print_success "Terraform deployment completed successfully!"
}

# Test the deployed infrastructure
test_infrastructure() {
    print_status "Testing deployed infrastructure..."
    
    # Get outputs
    VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "N/A")
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "N/A")
    KMS_KEY_ARN=$(terraform output -raw kms_key_arn 2>/dev/null || echo "N/A")
    
    print_status "Infrastructure outputs:"
    echo "  VPC ID: $VPC_ID"
    echo "  S3 Bucket: $S3_BUCKET"
    echo "  KMS Key ARN: $KMS_KEY_ARN"
    
    # Test S3 bucket
    if [ "$S3_BUCKET" != "N/A" ]; then
        print_status "Testing S3 bucket access..."
        if aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
            print_success "S3 bucket is accessible!"
        else
            print_warning "S3 bucket access test failed"
        fi
    fi
    
    print_success "Infrastructure testing completed!"
}

# Clean up
cleanup() {
    print_status "Cleaning up..."
    rm -f tfplan
    print_success "Cleanup completed!"
}

# Main deployment function
main() {
    echo "🚀 Starting Video Upload Platform Deployment..."
    echo "================================================"
    
    # Check prerequisites
    check_prerequisites
    
    # Deploy infrastructure
    init_terraform
    validate_terraform
    plan_terraform
    apply_terraform
    
    # Test deployment
    test_infrastructure
    
    # Cleanup
    cleanup
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "================================================"
    echo ""
    echo "Next steps:"
    echo "1. Test the Lambda functions"
    echo "2. Configure API Gateway"
    echo "3. Set up Cognito User Pool"
    echo "4. Deploy the frontend application"
    echo ""
    echo "For more information, check the README.md file."
}

# Handle script interruption
trap 'print_error "Deployment interrupted by user"; exit 1' INT

# Run main function
main "$@"
