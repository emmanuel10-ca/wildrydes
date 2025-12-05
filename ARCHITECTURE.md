# Wild Rydes Architecture Documentation

## High-Level Architecture Diagram

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                              INTERNET USERS                              ║
╚═════════════════════════════════╦═════════════════════════════════════════╝
                                  │ HTTP/HTTPS (Port 80)
                    ┌─────────────▼──────────┐
                    │  Internet Gateway (IGW) │
                    └─────────────┬──────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
   ┌────▼──────┐           ┌─────▼────┐           ┌────────▼────┐
   │ Elastic IP│           │ Elastic IP│           │  NAT Gateway│
   │     #1    │           │     #2    │           │   (Route)   │
   └────┬──────┘           └─────┬────┘           └────────┬────┘
        │                        │                         │
╔═══════▼════════════════════════▼═════════════════════════▼════════════════╗
║                               VPC (10.0.0.0/16)                           ║
║  ┌───────────────────────────────────────────────────────────────────┐   ║
║  │                                                                   │   ║
║  │ ┌─────────────────────────┐    ┌──────────────────────────┐      │   ║
║  │ │  PUBLIC SUBNET 1        │    │  PUBLIC SUBNET 2         │      │   ║
║  │ │  (10.0.1.0/24)          │    │  (10.0.2.0/24)           │      │   ║
║  │ │  AZ: us-east-1a         │    │  AZ: us-east-1b          │      │   ║
║  │ │                         │    │                          │      │   ║
║  │ │  ┌─────────────────┐    │    │  ┌──────────────────┐    │      │   ║
║  │ │  │  ALB            │    │    │  │  ALB             │    │      │   ║
║  │ │  │  Port: 80       │    │    │  │  Port: 80        │    │      │   ║
║  │ │  │  Listener: HTTP │    │    │  │  Listener: HTTP  │    │      │   ║
║  │ │  │                 │    │    │  │                  │    │      │   ║
║  │ │  └────────┬────────┘    │    │  └────────┬─────────┘    │      │   ║
║  │ │           │             │    │           │              │      │   ║
║  │ └───────────┼─────────────┘    └───────────┼──────────────┘      │   ║
║  │             │                              │                      │   ║
║  │             └──────────────┬───────────────┘                      │   ║
║  │                            │                                      │   ║
║  │  ┌──────────────────────────▼────────────────────────────┐       │   ║
║  │  │         TARGET GROUP (Port 8080)                     │       │   ║
║  │  │         Health Check: /health (HTTP 200-299)        │       │   ║
║  │  │         Interval: 30s, Timeout: 5s, Retries: 3     │       │   ║
║  │  └──────────────────────────┬────────────────────────────┘       │   ║
║  │                            │                                      │   ║
║  │                            │                                      │   ║
║  │  ┌─────────────────────────┼─────────────────────────────┐       │   ║
║  │  │                         │                             │       │   ║
║  │  ▼                         ▼                             ▼       │   ║
║  │ ┌────────────────────┐   ┌────────────────────┐   ┌──────────┐  │   ║
║  │ │ PRIVATE SUBNET 1   │   │ PRIVATE SUBNET 2   │   │PRIVATE  │  │   ║
║  │ │ (10.0.10.0/24)     │   │ (10.0.11.0/24)     │   │SUBNET 3 │  │   ║
║  │ │ AZ: us-east-1a     │   │ AZ: us-east-1b     │   │NAT GW 1 │  │   ║
║  │ │                    │   │                    │   └──────────┘  │   ║
║  │ │ ┌────────────────┐ │   │ ┌────────────────┐ │                 │   ║
║  │ │ │ ECS Task #1    │ │   │ │ ECS Task #2    │ │                 │   ║
║  │ │ │ Fargate        │ │   │ │ Fargate        │ │                 │   ║
║  │ │ │ CPU: 256       │ │   │ │ CPU: 256       │ │                 │   ║
║  │ │ │ Memory: 512MB  │ │   │ │ Memory: 512MB  │ │                 │   ║
║  │ │ │ Port: 8080     │ │   │ │ Port: 8080     │ │                 │   ║
║  │ │ │ Node.js App    │ │   │ │ Node.js App    │ │                 │   ║
║  │ │ └────────────────┘ │   │ └────────────────┘ │                 │   ║
║  │ │                    │   │                    │                 │   ║
║  │ │ ECR Image Pull ◄───┼───┼────► ECR Repo     │                 │   ║
║  │ │ CloudWatch Logs ───┼───┼────► CloudWatch   │                 │   ║
║  │ └────────────────────┘   └────────────────────┘                 │   ║
║  │                                                                   │   ║
║  └───────────────────────────────────────────────────────────────────┘   ║
╚═══════════════════════════════════════════════════════════════════════════╝

                        ┌─────────────────────┐
                        │  AUTO SCALING       │
                        │  Min: 2 Tasks       │
                        │  Max: 4 Tasks       │
                        │  Target: 70% CPU    │
                        └─────────────────────┘
```

## CI/CD Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                           │
│  STAGE 1: SOURCE                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  GitHub Repository                                              │   │
│  │  ├── app.js           (Express Application)                     │   │
│  │  ├── package.json     (Dependencies)                            │   │
│  │  ├── Dockerfile       (Container Image Definition)             │   │
│  │  ├── buildspec.yml    (Build Instructions)                     │   │
│  │  └── imagedefinitions.json (ECS Task Definition)               │   │
│  │                                                                 │   │
│  │  Trigger: Git Push (Webhook)                                  │   │
│  └────────────────────┬──────────────────────────────────────────┘   │
│                       │ SourceOutput Artifact                         │
│                       ▼                                               │
│  STAGE 2: BUILD                                                       │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  AWS CodeBuild Project                                          │   │
│  │  ┌────────────────────────────────────────────────────────────┐ │   │
│  │  │ Build Phase:                                               │ │   │
│  │  │ 1. Pre-build:  Login to ECR                               │ │   │
│  │  │ 2. Build:      docker build -t repo:tag .                │ │   │
│  │  │ 3. Post-build: docker push to ECR                         │ │   │
│  │  │                Generate imagedefinitions.json             │ │   │
│  │  └────────────────────────────────────────────────────────────┘ │   │
│  │                                                                 │   │
│  │  Environment:                                                  │   │
│  │  ├── AWS_ACCOUNT_ID    (ECR Repo URI)                        │   │
│  │  ├── AWS_DEFAULT_REGION (Region)                            │   │
│  │  ├── IMAGE_REPO_NAME   (wildrydes-app)                      │   │
│  │  └── IMAGE_TAG         (latest or commit hash)              │   │
│  │                                                                 │   │
│  │  Artifacts: BuildOutput (imagedefinitions.json)              │   │
│  └────────────────────┬──────────────────────────────────────────┘   │
│                       │ BuildOutput Artifact                         │
│                       ▼                                               │
│  STAGE 3: DEPLOY                                                      │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  AWS CodePipeline → ECS Service Update                         │   │
│  │                                                                 │   │
│  │  Update Process:                                              │   │
│  │  1. Read imagedefinitions.json                                │   │
│  │  2. Create new task definition with new image                │   │
│  │  3. Update ECS service to use new task definition            │   │
│  │  4. Gradual deployment (rolling update):                     │   │
│  │     - Keep 100% of tasks healthy                             │   │
│  │     - Replace one task at a time                             │   │
│  │  5. ALB health checks validate new tasks                     │   │
│  │                                                                 │   │
│  │  Rollback:                                                     │   │
│  │  - If health check fails → automatic rollback enabled        │   │
│  │  - Deployment circuit breaker active                         │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘

                              ▼
                    ┌─────────────────────┐
                    │  ECS SERVICE UPDATED│
                    │  New Image Running  │
                    │  on Fargate Tasks   │
                    └─────────────────────┘
```

## Data Flow Diagram

```
┌──────────────┐
│ Internet User│
└──────┬───────┘
       │ HTTP Request (Port 80)
       │
       ▼
┌─────────────────────────────────┐
│ Application Load Balancer (ALB) │
│ ├─ Listener: 0.0.0.0:80         │
│ ├─ Rules: Path-based routing    │
│ └─ SSL/TLS Termination (optional)│
└──────┬────────────────────────────┘
       │ Forward to Target Group
       │ (Port 8080)
       │
       ├───────────┬──────────────┐
       │           │              │
       ▼           ▼              ▼
  ┌─────────┐ ┌─────────┐   ┌─────────┐
  │ Task #1 │ │ Task #2 │   │ Task #3 │
  │Port 8080│ │Port 8080│   │Port 8080│
  │ Express │ │ Express │   │ Express │
  │  App    │ │  App    │   │  App    │
  └────┬────┘ └────┬────┘   └────┬────┘
       │           │             │
       └───────────┼─────────────┘
                   │
        Response   │ JSON/HTML
        ◄──────────┘
       │
       ▼
┌──────────────┐
│ Internet User│
│ (Updated)    │
└──────────────┘
```

## Auto-Scaling Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CloudWatch Metrics                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ ECS Service:                                           │ │
│  │ ├─ CPUUtilization: 45%  ┐                             │ │
│  │ ├─ MemoryUtilization: 38% ├─► Evaluation Period: 60s  │ │
│  │ └─ Status: Running        │                           │ │
│  │ ┌────────────────────────────────────────────────────┐ │
│  │ │ Target Tracking Metric: 70% CPU Target            │ │
│  │ └────────────────────────────────────────────────────┘ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────┬─────────────────────────────────┘
                           │
                   CPU < 70% (Scale In)
                           │
                    ┌──────▼──────┐
                    │ Scale Policy│
                    │  Cooldown:  │
                    │  300s (5m)  │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
     ┌─────────┐      ┌─────────┐     ┌─────────┐
     │ Task #1 │      │ Task #2 │     │ Task #3 │
     │ (Remove)│      │ (Keep)  │     │ (Keep)  │
     └────┬────┘      └─────────┘     └─────────┘
          │
          │ Graceful Shutdown (30s timeout)
          │
          ▼
     ┌─────────┐
     │Draining │
     │ Connections
     │ Closed  │
     └────┬────┘
          │
          ▼
     ┌─────────┐
     │ Task    │
     │ Removed │
     │ Current │
     │ Count:2 │
     └─────────┘

                   (If CPU > 70%)
                   Scale Out
                           │
                    ┌──────▼──────┐
                    │ Add Tasks   │
                    │ Cooldown:   │
                    │ 60s         │
                    └──────┬──────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ New Task #4  │
                    │ Pulling ECR  │
                    │ Image...     │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Running      │
                    │ Current:3    │
                    │ Registered to│
                    │ ALB          │
                    └──────────────┘
```

## Monitoring & Alarms Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 CloudWatch Alarms                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Build Failure Alarm                              │  │
│  │    Metric: AWS/CodeBuild FailedBuilds               │  │
│  │    Threshold: >= 1 failed build                     │  │
│  │    Action: SNS Notification                          │  │
│  │                                                      │  │
│  │ 2. Pipeline Failure Alarm                           │  │
│  │    Metric: AWS/CodePipeline ExecutionFailure        │  │
│  │    Threshold: >= 1 failure                          │  │
│  │    Action: SNS Notification                          │  │
│  │                                                      │  │
│  │ 3. High CPU Alarm                                   │  │
│  │    Metric: AWS/ECS CPUUtilization                   │  │
│  │    Threshold: > 80%                                 │  │
│  │    Evaluation: 2 periods of 60s                     │  │
│  │    Action: Scale out (trigger Auto Scaling)        │  │
│  │                                                      │  │
│  │ 4. High Memory Alarm                                │  │
│  │    Metric: AWS/ECS MemoryUtilization                │  │
│  │    Threshold: > 80%                                 │  │
│  │    Evaluation: 2 periods of 60s                     │  │
│  │    Action: SNS Notification                          │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────┬─────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   ┌────────┐    ┌──────────┐   ┌────────┐
   │SNS     │    │ECS       │   │Lambda  │
   │Topic   │    │Auto      │   │Custom  │
   │Notify  │    │Scaling   │   │Action  │
   │Team    │    │Triggers  │   │Handler │
   └────────┘    └──────────┘   └────────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
                       ▼
            ┌─────────────────────┐
            │ CloudWatch Logs     │
            │ ├─ /ecs/wildrydes   │
            │ │  └─ Retain: 7days │
            │ └─ Log Streams      │
            │    └─ Task Events   │
            └─────────────────────┘
```

## Security Groups Configuration

```
┌──────────────────────────────────────────────────┐
│         ALB Security Group                       │
│  Inbound Rules:                                  │
│  ├─ HTTP (80): 0.0.0.0/0  [From Internet]       │
│  ├─ HTTPS (443): 0.0.0.0/0 [Optional]           │
│  Outbound Rules:                                 │
│  └─ All Traffic ⚙ ECS SG (Port 8080)            │
└──────────────┬───────────────────────────────────┘
               │
               ▼ (Port 8080)
┌──────────────────────────────────────────────────┐
│         ECS Security Group                       │
│  Inbound Rules:                                  │
│  ├─ TCP 8080: From ALB SG  [From ALB]            │
│  Outbound Rules:                                 │
│  ├─ All Traffic: 0.0.0.0/0 [ECR, CloudWatch]    │
│  └─ DNS (53): 0.0.0.0/0    [Name Resolution]    │
└──────────────────────────────────────────────────┘
```

## Resource Dependencies

```
CloudFormation Stack
├── VPC
│   ├── Public Subnets (2x)
│   │   └── ALB & NAT Gateways
│   ├── Private Subnets (2x)
│   │   └── ECS Tasks
│   ├── Internet Gateway
│   ├── Route Tables (3x)
│   └── Security Groups (2x)
│
├── ECS Infrastructure
│   ├── ECS Cluster
│   │   ├── ECS Service
│   │   │   ├── Task Definition
│   │   │   └── Load Balancer Integration
│   │   └── Auto Scaling
│   │       └── Scaling Policy (CPU-based)
│   └── ECR Repository
│
├── Load Balancing
│   ├── Application Load Balancer
│   ├── Target Group
│   └── ALB Listener
│
├── CI/CD Pipeline
│   ├── CodePipeline
│   │   ├── Source Stage (GitHub)
│   │   ├── Build Stage (CodeBuild)
│   │   └── Deploy Stage (ECS)
│   ├── CodeBuild Project
│   ├── IAM Roles (2x)
│   └── S3 Bucket (Artifacts)
│
├── Monitoring
│   ├── CloudWatch Log Group
│   ├── CloudWatch Alarms (4x)
│   └── CloudWatch Metrics
│
└── IAM
    ├── ECS Task Execution Role
    ├── ECS Task Role
    ├── CodeBuild Service Role
    └── CodePipeline Service Role
```

---

**Last Updated**: December 2025
**Version**: 1.0.0
