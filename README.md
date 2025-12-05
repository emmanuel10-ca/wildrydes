# Wild Rydes - Infrastructure as Code Solution

Complete AWS CloudFormation solution for Wild Rydes' scalable, highly redundant website infrastructure using AWS ECS Fargate, Application Load Balancer, and CI/CD CodePipeline.

## 📋 Overview

This solution implements Wild Rydes' entire infrastructure stack as Infrastructure as Code (IaC) using AWS CloudFormation. It includes:

- **Highly Scalable**: Auto-scaling ECS service based on CPU utilization
- **Highly Redundant**: Multi-AZ deployment with load balancing
- **CI/CD Integrated**: Automated build and deployment pipeline
- **Fully Monitored**: CloudWatch metrics and alarms
- **Production Ready**: Security best practices, health checks, and rollback capabilities

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└───────────────────────┬─────────────────────────────────────┘
                        │ (Port 80)
            ┌───────────▼──────────┐
            │   Internet Gateway   │
            └───────────┬──────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   ┌────▼───┐      ┌────▼───┐
   │ Public │      │ Public │
   │Subnet 1│      │Subnet 2│
   │        │      │        │
   │  ALB   │      │  ALB   │
   └────┬───┘      └────┬───┘
        │               │
        └───────┬───────┘
                │
    ┌───────────┼───────────┐
    │           │           │
┌───▼────┐ ┌───▼────┐ ┌────▼────┐
│ Private│ │ Private│ │ CodePipe│
│Subnet 1│ │Subnet 2│ │  line   │
│        │ │        │ │         │
│ECS Task│ │ECS Task│ │CodeBuild│
│        │ │        │ │  ECR    │
└────────┘ └────────┘ └─────────┘

        └────────────────────────────┘
              (NAT Gateways)
```

### Key Components

#### Networking
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (for ALB)
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24 (for ECS tasks)
- **NAT Gateways**: High availability outbound access

#### Load Balancing
- **Application Load Balancer**: Internet-facing on port 80
- **Target Group**: Health checks every 30 seconds
- **Auto-scaling**: 2-4 tasks based on 70% CPU threshold

#### Container Orchestration
- **ECS Cluster**: With Container Insights enabled
- **ECS Fargate**: Serverless container compute
- **Task Definition**: Node.js application with health checks

#### CI/CD Pipeline
- **Source Stage**: GitHub repository webhook
- **Build Stage**: CodeBuild with Docker build
- **Deploy Stage**: ECS service update with new image
- **Artifact Storage**: S3 bucket for build artifacts

#### Monitoring
- **CloudWatch Logs**: ECS container logs retained for 7 days
- **CloudWatch Alarms**: Build failure, pipeline failure, CPU/memory alerts

## 📦 Project Structure

```
wildrydes/
├── cloudformation-template.yaml    # Main CloudFormation template
├── app.js                          # Node.js Express application
├── package.json                    # NPM dependencies
├── Dockerfile                      # Multi-stage Docker build
├── buildspec.yml                   # CodeBuild build specification
├── .dockerignore                   # Docker build ignore rules
├── deploy.sh                       # Bash deployment script
├── deploy.ps1                      # PowerShell deployment script
├── DEPLOYMENT_GUIDE.md             # Detailed deployment guide
├── README.md                       # This file
└── .gitignore                      # Git ignore rules
```

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with appropriate IAM permissions
2. **GitHub Account** with repository access
3. **AWS CLI v2** installed and configured
4. **Docker** installed (for local testing)
5. **Git** installed

### Step 1: Create GitHub Repository

```bash
# Create a new GitHub repository and clone it
git clone https://github.com/your-username/wildrydes.git
cd wildrydes

# Copy all files from this solution
```

### Step 2: Generate GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Click "Generate new token"
3. Set expiration and select scopes:
   - `repo` (Full control of private repositories)
   - `admin:repo_hook` (Full control of repository hooks)
4. Copy the token (you won't see it again!)

### Step 3: Deploy Infrastructure

#### Option A: Using PowerShell (Windows)

```powershell
# Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run deployment script
.\deploy.ps1 -StackName wildrydes-stack `
            -EnvironmentName wildrydes `
            -GitHubRepo "https://github.com/your-username/wildrydes" `
            -GitHubBranch "main" `
            -GitHubToken "your-github-token"
```

#### Option B: Using Bash (Linux/macOS)

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment script
./deploy.sh wildrydes-stack wildrydes \
  "https://github.com/your-username/wildrydes" \
  "main" \
  "cloudformation-template.yaml" \
  "us-east-1"
```

#### Option C: Using AWS CLI

```bash
# Set variables
STACK_NAME="wildrydes-stack"
ENVIRONMENT_NAME="wildrydes"
GITHUB_REPO="https://github.com/your-username/wildrydes"
GITHUB_BRANCH="main"
GITHUB_TOKEN="your-github-token"
REGION="us-east-1"

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
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name $STACK_NAME \
  --region $REGION
```

### Step 4: Get Application URL

```bash
# Retrieve ALB DNS name
aws cloudformation describe-stacks \
  --stack-name wildrydes-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text
```

### Step 5: Test Application

```bash
# Get ALB DNS
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name wildrydes-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

# Test endpoints
curl http://$ALB_DNS/              # Home page
curl http://$ALB_DNS/health        # Health check
curl http://$ALB_DNS/api/rides     # Rides API
```

## 🔄 CI/CD Pipeline Usage

### Trigger Deployment

Once the stack is created, any push to the GitHub repository will:

1. **Source Stage**: CodePipeline detects code push
2. **Build Stage**: CodeBuild:
   - Checks out code
   - Builds Docker image
   - Pushes to ECR repository
3. **Deploy Stage**: CodePipeline:
   - Creates new task definition
   - Updates ECS service
   - Gradually shifts traffic (with health checks)

### Example: Update Application

```bash
# Make changes to app.js
# Commit and push
git add app.js
git commit -m "Update application"
git push origin main

# Monitor deployment
aws codepipeline get-pipeline-state \
  --name wildrydes-pipeline
```

## 📊 Monitoring

### CloudWatch Logs

```bash
# View real-time ECS logs
aws logs tail /ecs/wildrydes-app --follow

# Get recent logs
aws logs get-log-events \
  --log-group-name /ecs/wildrydes-app \
  --log-stream-name "ecs/wildrydes-app/$(date +%s)" \
  --limit 100
```

### CloudWatch Alarms

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix wildrydes

# Get specific alarm status
aws cloudwatch describe-alarms \
  --alarm-names wildrydes-build-failure
```

### ECS Metrics

```bash
# Get service metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=wildrydes-service \
               Name=ClusterName,Value=wildrydes-cluster \
  --start-time 2025-12-04T00:00:00Z \
  --end-time 2025-12-05T00:00:00Z \
  --period 300 \
  --statistics Average,Maximum
```

## 🔧 Configuration

### Environment Variables

Configure via CloudFormation parameters:

- **EnvironmentName**: Resource name prefix (default: wildrydes)
- **ContainerPort**: Application port (default: 8080)
- **DesiredCount**: Initial ECS tasks (default: 2)
- **GitHubRepo**: Repository URL
- **GitHubBranch**: Branch to deploy (default: main)

### Update Stack

```bash
# Update any parameter
aws cloudformation update-stack \
  --stack-name wildrydes-stack \
  --template-body file://cloudformation-template.yaml \
  --parameters \
    ParameterKey=DesiredCount,ParameterValue=4 \
  --capabilities CAPABILITY_NAMED_IAM
```

## 🛡️ Security Features

- **VPC Isolation**: Private subnets for ECS tasks
- **Security Groups**: Restricted ingress rules
- **IAM Roles**: Least privilege access
- **Non-root Container User**: Application runs as nodejs user
- **Health Checks**: Automated task restart on failure
- **Network Isolation**: NAT Gateways for private subnet egress
- **S3 Bucket Blocking**: Public access blocked
- **Image Scanning**: ECR scans images on push

## 📈 Scalability

### Auto-Scaling Configuration

- **Minimum Tasks**: 2 (multi-AZ redundancy)
- **Maximum Tasks**: 4 (cost control)
- **Target CPU**: 70% utilization
- **Scale-out**: 60 seconds cooldown
- **Scale-in**: 300 seconds cooldown

### Manual Scaling

```bash
# Update desired count
aws ecs update-service \
  --cluster wildrydes-cluster \
  --service wildrydes-service \
  --desired-count 6
```

## 🧹 Cleanup

### Delete All Resources

```bash
# Empty S3 bucket first
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rm s3://wildrydes-pipeline-artifacts-$ACCOUNT_ID --recursive

# Delete stack
aws cloudformation delete-stack \
  --stack-name wildrydes-stack

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name wildrydes-stack
```

## 🐛 Troubleshooting

### Common Issues

#### BuildSpec Error
- Ensure `buildspec.yml` is in repository root
- Verify GitHub token is valid
- Check CodeBuild service role permissions

#### ECS Tasks Not Starting
- Check CloudWatch logs: `/ecs/wildrydes-app`
- Verify task CPU/memory allocation (256 CPU, 512 MB memory)
- Check security group allows egress for ECR pull

#### ALB Not Routing Traffic
- Verify target group health check (HTTP 200-299)
- Check ECS task security group allows ALB on port 8080
- Ensure application is listening on 0.0.0.0:8080

#### Pipeline Stuck
- Check S3 bucket permissions for artifacts
- Verify CodeBuild service role has ECR push permissions
- Review CloudPipeline stage action configuration

### Enable Debug Logging

```bash
# View CodeBuild logs
aws codebuild batch-get-builds \
  --ids $(aws codepipeline get-pipeline-state \
    --name wildrydes-pipeline \
    --query 'stageStates[1].latestExecution.pipelineExecutionId' \
    --output text) \
  --query 'builds[0].logs.cloudWatchLogs.groupName'

# View CloudFormation events
aws cloudformation describe-stack-events \
  --stack-name wildrydes-stack \
  --query 'StackEvents[].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table
```

## 📚 Additional Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)

## 📝 CloudFormation Template Overview

The template includes:

| Resource | Type | Purpose |
|----------|------|---------|
| VPC | AWS::EC2::VPC | Virtual network for all resources |
| Subnets (4x) | AWS::EC2::Subnet | Public and private subnets across 2 AZs |
| NAT Gateways (2x) | AWS::EC2::NatGateway | Outbound internet access for private subnets |
| ALB | AWS::ElasticLoadBalancingV2::LoadBalancer | Traffic distribution |
| Target Group | AWS::ElasticLoadBalancingV2::TargetGroup | ECS task registration |
| ECR Repository | AWS::ECR::Repository | Docker image storage |
| ECS Cluster | AWS::ECS::Cluster | Container orchestration |
| ECS Service | AWS::ECS::Service | Application service definition |
| ECS Task Definition | AWS::ECS::TaskDefinition | Container specification |
| Auto Scaling | AWS::ApplicationAutoScaling::* | Dynamic scaling |
| CodePipeline | AWS::CodePipeline::Pipeline | CI/CD orchestration |
| CodeBuild | AWS::CodeBuild::Project | Docker image build |
| IAM Roles | AWS::IAM::Role | Service permissions |
| CloudWatch | AWS::Logs::*, AWS::CloudWatch::* | Monitoring and alerts |

## 📄 License

This solution is provided as-is for educational and commercial use.

## 👥 Support

For issues or questions, refer to the DEPLOYMENT_GUIDE.md or contact your DevOps team.

---

**Version**: 1.0.0  
**Last Updated**: December 2025  
**Author**: DevOps Team
