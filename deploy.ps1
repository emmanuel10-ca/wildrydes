# Wild Rydes CloudFormation Deployment Script
# This script automates the deployment of the Wild Rydes infrastructure

param(
    [Parameter(Mandatory = $false)]
    [string]$StackName = "wildrydes-stack",
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = "wildrydes",
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubRepo = "https://github.com/your-username/your-repo",
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubBranch = "main",
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubToken = "",
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = "cloudformation-template.yaml",
    
    [Parameter(Mandatory = $false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory = $false)]
    [string]$Action = "create"
)

# Colors for output
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"

# Functions
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $SuccessColor
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $ErrorColor
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $InfoColor
}

# Main script
Write-Info "Wild Rydes CloudFormation Deployment Script"
Write-Info "============================================"
Write-Host ""

# Validate prerequisites
Write-Info "Validating prerequisites..."

# Check AWS CLI
try {
    $AwsVersion = aws --version 2>$null
    Write-Success "AWS CLI installed: $AwsVersion"
}
catch {
    Write-Error-Custom "AWS CLI not found. Please install AWS CLI."
    exit 1
}

# Check if template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Error-Custom "Template file not found: $TemplateFile"
    exit 1
}
Write-Success "CloudFormation template found"

# Validate template
Write-Info ""
Write-Info "Validating CloudFormation template..."
try {
    aws cloudformation validate-template `
        --template-body file://$TemplateFile `
        --region $Region | Out-Null
    Write-Success "Template validation passed"
}
catch {
    Write-Error-Custom "Template validation failed: $_"
    exit 1
}

# Get AWS Account ID
$AwsAccountId = aws sts get-caller-identity --query Account --output text
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Failed to get AWS Account ID"
    exit 1
}
Write-Success "AWS Account ID: $AwsAccountId"

# Prompt for GitHub token if not provided
if ([string]::IsNullOrEmpty($GitHubToken)) {
    Write-Host ""
    Write-Info "GitHub personal access token required"
    $GitHubTokenSecure = Read-Host "Enter your GitHub personal access token (input hidden)" -AsSecureString
    $GitHubToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($GitHubTokenSecure)
    )
}

# Prepare parameters
$Parameters = @(
    "ParameterKey=EnvironmentName,ParameterValue=$EnvironmentName"
    "ParameterKey=GitHubRepo,ParameterValue=$GitHubRepo"
    "ParameterKey=GitHubBranch,ParameterValue=$GitHubBranch"
    "ParameterKey=GitHubToken,ParameterValue=$GitHubToken"
)

Write-Host ""
Write-Info "Deployment Configuration:"
Write-Host "  Stack Name: $StackName"
Write-Host "  Environment: $EnvironmentName"
Write-Host "  GitHub Repo: $GitHubRepo"
Write-Host "  GitHub Branch: $GitHubBranch"
Write-Host "  Region: $Region"
Write-Host ""

# Check if stack already exists
$StackExists = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    2>$null

if ($StackExists) {
    Write-Info "Stack already exists. Updating..."
    $Action = "update"
}

# Create or update stack
Write-Info ""
Write-Info "Starting CloudFormation deployment..."

if ($Action -eq "update") {
    try {
        aws cloudformation update-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --parameters $Parameters `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region
        Write-Success "Stack update initiated"
    }
    catch {
        Write-Error-Custom "Failed to update stack: $_"
        exit 1
    }
}
else {
    try {
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --parameters $Parameters `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region
        Write-Success "Stack creation initiated"
    }
    catch {
        Write-Error-Custom "Failed to create stack: $_"
        exit 1
    }
}

# Wait for stack operation to complete
Write-Info ""
Write-Info "Waiting for stack operation to complete (this may take 10-15 minutes)..."

$WaitEvent = "stack-$(if ($Action -eq 'update') { 'update' } else { 'create' })-complete"
$StackCreateComplete = $false
$MaxAttempts = 180  # 30 minutes with 10-second intervals
$Attempts = 0

while (-not $StackCreateComplete -and $Attempts -lt $MaxAttempts) {
    try {
        $StackStatus = aws cloudformation describe-stacks `
            --stack-name $StackName `
            --region $Region `
            --query 'Stacks[0].StackStatus' `
            --output text 2>$null
        
        if ($StackStatus -match "COMPLETE$") {
            $StackCreateComplete = $true
        }
        elseif ($StackStatus -match "ROLLBACK|FAILED") {
            Write-Error-Custom "Stack deployment failed with status: $StackStatus"
            exit 1
        }
        else {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 10
            $Attempts++
        }
    }
    catch {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 10
        $Attempts++
    }
}

Write-Host ""
if ($StackCreateComplete) {
    Write-Success "Stack deployment completed successfully"
}
else {
    Write-Error-Custom "Stack deployment timed out"
    exit 1
}

# Retrieve outputs
Write-Info ""
Write-Info "Stack Outputs:"
Write-Host ""

$StackOutputs = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query 'Stacks[0].Outputs' `
    --output table

Write-Host $StackOutputs

# Additional information
Write-Info ""
Write-Info "Deployment Summary:"
Write-Host "  Stack Name: $StackName"
Write-Host "  Region: $Region"
Write-Host "  Account ID: $AwsAccountId"
Write-Host ""

# Next steps
Write-Info "Next Steps:"
Write-Host "1. Update your GitHub repository with the application code"
Write-Host "2. Configure your GitHub repository webhook in CodePipeline"
Write-Host "3. Push code to GitHub to trigger the CI/CD pipeline"
Write-Host "4. Monitor the deployment in CodePipeline console"
Write-Host ""

Write-Success "Deployment script completed successfully!"
