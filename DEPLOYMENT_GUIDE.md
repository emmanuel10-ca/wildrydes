# Wild Rydes Infrastructure as Code Deployment Guide

This repository contains the complete Infrastructure as Code solution for Wild Rydes' AWS infrastructure using CloudFormation, ECS Fargate, and CI/CD with CodePipeline.

## Architecture Overview

### Infrastructure Components

The CloudFormation template deploys the following resources:

#### Networking
- **VPC** with CIDR block 10.0.0.0/16
- **Public Subnets** (2x) for Application Load Balancer
- **Private Subnets** (2x) for ECS tasks
- **Internet Gateway** for public internet access
- **NAT Gateways** (2x) for private subnet outbound access
- **Route Tables** with appropriate routing configuration

#### Load Balancing
- **Application Load Balancer (ALB)** for distributing traffic
- **Target Group** with health checks
- **Security Groups** for ALB and ECS tasks

#### Container Orchestration
- **ECS Cluster** with Container Insights enabled
- **ECS Service** running on Fargate with desired count of 2 tasks
- **Task Definition** specifying container configuration
- **Auto Scaling** policies based on CPU utilization (70% target)

#### Container Registry
- **Amazon ECR Repository** for storing Docker images
- **Image Scanning** enabled on push

#### CI/CD Pipeline
- **CodeBuild Project** for building Docker images
- **CodePipeline** with three stages:
  1. Source: GitHub repository
  2. Build: Docker build and push to ECR
  3. Deploy: Update ECS service with new image

#### Monitoring & Logging
- **CloudWatch Log Group** for ECS container logs
- **CloudWatch Alarms** for:
  - Build failures
  - Pipeline failures
  - High ECS CPU utilization
  - High ECS memory utilization

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Account** with repository access
3. **GitHub Personal Access Token** with `repo` and `admin:repo_hook` scopes
4. **AWS CLI** configured with credentials
5. **Docker** installed locally (for building and testing)

## Deployment Steps

### Step 1: Prepare GitHub Repository

```bash
# Clone or create a repository with the following files:
# - Dockerfile
# - app.js
# - package.json
# - buildspec.yml
```

### Step 2: Generate GitHub Personal Access Token

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Click "Generate new token"
3. Select scopes: `repo` and `admin:repo_hook`
4. Copy and save the token securely

### Step 3: Deploy CloudFormation Stack

```bash
# Set variables
STACK_NAME="wildrydes-stack"
ENVIRONMENT_NAME="wildrydes"
GITHUB_REPO="https://github.com/your-username/your-repo"
GITHUB_BRANCH="main"
GITHUB_TOKEN="your-personal-access-token"

# Validate template
aws cloudformation validate-template \
  --template-body file://cloudformation-template.yaml

# Create stack
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://cloudformation-template.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT_NAME \
    ParameterKey=GitHubRepo,ParameterValue=$GITHUB_REPO \
    ParameterKey=GitHubBranch,ParameterValue=$GITHUB_BRANCH \
    ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN \
  --capabilities CAPABILITY_NAMED_IAM

# Monitor stack creation
aws cloudformation wait stack-create-complete \
  --stack-name $STACK_NAME

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs'
```

### Step 4: Initial Docker Image Build and Push (Optional)

If you want to manually test before connecting CodePipeline:

```bash
# Get AWS credentials
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"  # Change to your region

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Get ECR repository name from stack outputs
REPO_NAME="wildrydes-app"

# Build image
docker build -t $REPO_NAME:latest .

# Tag image
docker tag $REPO_NAME:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest

# Push to ECR
docker push \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
```

### Step 5: Verify Deployment

```bash
# Get ALB DNS name
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

# Test application
curl http://$ALB_DNS/
curl http://$ALB_DNS/health
curl http://$ALB_DNS/api/rides

# View ECS service
aws ecs describe-services \
  --cluster $ENVIRONMENT_NAME-cluster \
  --services $ENVIRONMENT_NAME-service \
  --region $AWS_REGION

# View CodePipeline status
aws codepipeline get-pipeline-state \
  --name $ENVIRONMENT_NAME-pipeline \
  --region $AWS_REGION
```

## Monitoring

### CloudWatch Logs
```bash
# View ECS container logs
aws logs tail /ecs/wildrydes-app --follow
```

### CloudWatch Alarms
The template creates four alarms:
1. **Build Failure Alarm** - Triggers when CodeBuild fails
2. **Pipeline Failure Alarm** - Triggers when CodePipeline fails
3. **High CPU Alarm** - Triggers when ECS CPU > 80%
4. **High Memory Alarm** - Triggers when ECS memory > 80%

View alarms in AWS Console or via CLI:
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix $ENVIRONMENT_NAME
```

## CI/CD Pipeline Workflow

1. **Developer** pushes code to GitHub repository
2. **CodePipeline** detects the change (Source stage)
3. **CodeBuild** pulls the repository and runs buildspec.yml
4. **Docker image** is built and pushed to ECR
5. **CodePipeline** triggers ECS deployment (Deploy stage)
6. **ECS Service** updates with new task definition
7. **ALB** gradually routes traffic to new tasks

## Scaling Configuration

The ECS service is configured with auto-scaling:
- **Minimum Tasks**: 2 (as specified in DesiredCount parameter)
- **Maximum Tasks**: 4
- **Target CPU Utilization**: 70%
- **Scale-out cooldown**: 60 seconds
- **Scale-in cooldown**: 300 seconds

Adjust by modifying the `ServiceScalingPolicy` in the CloudFormation template.

## Customization

### Change Application Port
```bash
aws cloudformation update-stack \
  --stack-name $STACK_NAME \
  --template-body file://cloudformation-template.yaml \
  --parameters \
    ParameterKey=ContainerPort,ParameterValue=3000 \
  --capabilities CAPABILITY_NAMED_IAM
```

### Change Desired Task Count
```bash
aws cloudformation update-stack \
  --stack-name $STACK_NAME \
  --template-body file://cloudformation-template.yaml \
  --parameters \
    ParameterKey=DesiredCount,ParameterValue=4 \
  --capabilities CAPABILITY_NAMED_IAM
```

## Cleanup

To delete all resources:

```bash
# Delete stack (this will also delete the S3 bucket if empty)
aws cloudformation delete-stack \
  --stack-name $STACK_NAME

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name $STACK_NAME

# Note: S3 bucket with artifacts may need to be emptied first
aws s3 rm s3://wildrydes-pipeline-artifacts-$AWS_ACCOUNT_ID --recursive
```

## Troubleshooting

### CodeBuild Failures
- Check build logs in CodeBuild console
- Verify GitHub token is valid
- Ensure buildspec.yml is in repository root

### ECS Task Failures
- Check ECS task logs in CloudWatch
- Verify security group allows traffic on container port
- Check task CPU/memory allocation

### Pipeline Stuck
- Check each stage in CodePipeline console
- Verify IAM roles have necessary permissions
- Check S3 bucket permissions for artifacts

### ALB Not Routing Traffic
- Verify target group health checks
- Check security group rules
- Ensure container is listening on correct port

## Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)

## Support

For issues or questions, contact the DevOps team.

---

**Last Updated**: December 2025
**Version**: 1.0.0
