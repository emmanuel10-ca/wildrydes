#!/bin/bash

# Wild Rydes CloudFormation Deployment Script
# This script automates the deployment of the Wild Rydes infrastructure

set -e

# Default values
STACK_NAME="${1:-wildrydes-stack}"
ENVIRONMENT_NAME="${2:-wildrydes}"
GITHUB_REPO="${3:-https://github.com/your-username/your-repo}"
GITHUB_BRANCH="${4:-main}"
TEMPLATE_FILE="${5:-cloudformation-template.yaml}"
REGION="${6:-us-east-1}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Main script
print_info "Wild Rydes CloudFormation Deployment Script"
print_info "============================================"
echo ""

# Validate prerequisites
print_info "Validating prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install AWS CLI."
    exit 1
fi
print_success "AWS CLI installed: $(aws --version)"

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    print_error "Template file not found: $TEMPLATE_FILE"
    exit 1
fi
print_success "CloudFormation template found"

# Validate template
print_info ""
print_info "Validating CloudFormation template..."
if ! aws cloudformation validate-template \
    --template-body file://"$TEMPLATE_FILE" \
    --region "$REGION" > /dev/null 2>&1; then
    print_error "Template validation failed"
    exit 1
fi
print_success "Template validation passed"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_success "AWS Account ID: $AWS_ACCOUNT_ID"

# Prompt for GitHub token
echo ""
print_info "GitHub personal access token required"
read -sp "Enter your GitHub personal access token (input hidden): " GITHUB_TOKEN
echo ""

# Prepare parameters
PARAMETERS=(
    "ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT_NAME"
    "ParameterKey=GitHubRepo,ParameterValue=$GITHUB_REPO"
    "ParameterKey=GitHubBranch,ParameterValue=$GITHUB_BRANCH"
    "ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN"
)

echo ""
print_info "Deployment Configuration:"
echo "  Stack Name: $STACK_NAME"
echo "  Environment: $ENVIRONMENT_NAME"
echo "  GitHub Repo: $GITHUB_REPO"
echo "  GitHub Branch: $GITHUB_BRANCH"
echo "  Region: $REGION"
echo ""

# Check if stack already exists
ACTION="create"
if aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    > /dev/null 2>&1; then
    print_info "Stack already exists. Updating..."
    ACTION="update"
fi

# Create or update stack
echo ""
print_info "Starting CloudFormation deployment..."

if [ "$ACTION" == "update" ]; then
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters "${PARAMETERS[@]}" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION"
    print_success "Stack update initiated"
else
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE" \
        --parameters "${PARAMETERS[@]}" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$REGION"
    print_success "Stack creation initiated"
fi

# Wait for stack operation to complete
echo ""
print_info "Waiting for stack operation to complete (this may take 10-15 minutes)..."

WAIT_EVENT="stack-$([ "$ACTION" = "update" ] && echo "update" || echo "create")-complete"

if aws cloudformation wait "$WAIT_EVENT" \
    --stack-name "$STACK_NAME" \
    --region "$REGION" 2>/dev/null; then
    print_success "Stack deployment completed successfully"
else
    print_error "Stack deployment failed or timed out"
    exit 1
fi

# Retrieve outputs
echo ""
print_info "Stack Outputs:"
echo ""

aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output table

# Additional information
echo ""
print_info "Deployment Summary:"
echo "  Stack Name: $STACK_NAME"
echo "  Region: $REGION"
echo "  Account ID: $AWS_ACCOUNT_ID"
echo ""

# Next steps
print_info "Next Steps:"
echo "1. Update your GitHub repository with the application code"
echo "2. Configure your GitHub repository webhook in CodePipeline"
echo "3. Push code to GitHub to trigger the CI/CD pipeline"
echo "4. Monitor the deployment in CodePipeline console"
echo ""

print_success "Deployment script completed successfully!"
