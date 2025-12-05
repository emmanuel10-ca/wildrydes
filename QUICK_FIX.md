# Quick Fix: Deploy Without ECS Service Tasks Initially

The Circuit Breaker error happens because:
1. CloudFormation tries to start 2 ECS tasks
2. No Docker image exists in ECR yet
3. Tasks fail to start
4. Circuit Breaker triggers and stops deployment

## Solution: Two-Phase Deployment

### Phase 1: Deploy Infrastructure (without running tasks)

Delete the current stack and redeploy with DesiredCount=0:

```powershell
# Delete failed stack
aws cloudformation delete-stack --stack-name wildrydes-stack --region us-east-1

# Wait for deletion
Start-Sleep -Seconds 30

# Deploy with NO tasks (DesiredCount=0)
aws cloudformation create-stack `
  --stack-name wildrydes-stack `
  --template-body file://cloudformation-template.yaml `
  --parameters `
    ParameterKey=EnvironmentName,ParameterValue=wildrydes `
    ParameterKey=DesiredCount,ParameterValue=0 `
    ParameterKey=GitHubRepo,ParameterValue=https://github.com/emmanuel10-ca/wildrydes `
    ParameterKey=GitHubBranch,ParameterValue=main `
    ParameterKey=GitHubToken,ParameterValue=<YOUR_GITHUB_TOKEN> `
  --capabilities CAPABILITY_NAMED_IAM `
  --region us-east-1

# Wait for stack creation
aws cloudformation wait stack-create-complete --stack-name wildrydes-stack --region us-east-1
```

### Phase 2: Build and Push Docker Image

On a machine with Docker installed:

```bash
# Navigate to project directory
cd /path/to/wildrydes

# Get AWS credentials and ECR info
export AWS_ACCOUNT_ID="149896763221"
export AWS_REGION="us-east-1"
export REPO_NAME="wildrydes-app"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build image
docker build -t $REPO_NAME:latest .

# Tag image
docker tag $REPO_NAME:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest

# Push to ECR
docker push \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest

echo "✅ Image pushed successfully!"
```

### Phase 3: Scale Up Service

Once the image is in ECR, update the service to start tasks:

```powershell
# Update desired count from 0 to 2
aws ecs update-service `
  --cluster wildrydes-cluster `
  --service wildrydes-service `
  --desired-count 2 `
  --region us-east-1

# Wait for tasks to be healthy (2-3 minutes)
# Check status in AWS Console or run:
aws ecs describe-services `
  --cluster wildrydes-cluster `
  --services wildrydes-service `
  --region us-east-1 `
  --query 'services[0].[runningCount,desiredCount,status]'
```

## Quick Command Sequence

```powershell
# All-in-one script to delete and redeploy with DesiredCount=0

aws cloudformation delete-stack --stack-name wildrydes-stack --region us-east-1
Start-Sleep -Seconds 30

aws cloudformation create-stack `
  --stack-name wildrydes-stack `
  --template-body file://cloudformation-template.yaml `
  --parameters ParameterKey=EnvironmentName,ParameterValue=wildrydes ParameterKey=DesiredCount,ParameterValue=0 ParameterKey=GitHubRepo,ParameterValue=https://github.com/emmanuel10-ca/wildrydes ParameterKey=GitHubBranch,ParameterValue=main ParameterKey=GitHubToken,ParameterValue=<YOUR_GITHUB_TOKEN> `
  --capabilities CAPABILITY_NAMED_IAM `
  --region us-east-1

# Monitor
aws cloudformation wait stack-create-complete --stack-name wildrydes-stack --region us-east-1
echo "✅ Stack deployed successfully!"
```

## After Docker Image is Available

```powershell
# Scale up to 2 tasks
aws ecs update-service `
  --cluster wildrydes-cluster `
  --service wildrydes-service `
  --desired-count 2 `
  --region us-east-1
```

---

## Why This Works

1. **Phase 1**: Deploys all infrastructure (VPC, ALB, ECR, CodePipeline, etc.) without starting ECS tasks
2. **Phase 2**: Builds and pushes the Docker image to ECR from a machine with Docker
3. **Phase 3**: Scales up the ECS service to run tasks with the now-available image

This avoids the Circuit Breaker error because tasks don't start until the image exists.
