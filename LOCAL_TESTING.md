# Local Testing Guide

This guide covers how to build and test the Wild Rydes application locally before deploying to AWS.

## Prerequisites

- **Node.js 18+** installed
- **Docker** installed and running
- **Docker Compose** (optional, for multi-container setups)

## Testing Node.js Application

### 1. Install Dependencies

```bash
npm install
```

### 2. Run Application Locally

```bash
# Start the application
npm start

# Application will be available at http://localhost:8080
```

### 3. Test Endpoints

In another terminal:

```bash
# Test home page
curl http://localhost:8080/

# Test health check
curl http://localhost:8080/health

# Test API endpoint
curl http://localhost:8080/api/rides
```

### 4. Development Mode

For development with auto-reload:

```bash
npm run dev
```

## Building Docker Image Locally

### 1. Build Image

```bash
docker build -t wildrydes-app:latest .
```

### 2. Run Container

```bash
# Run the container
docker run -p 8080:8080 \
  --name wildrydes-container \
  -e APP_PORT=8080 \
  wildrydes-app:latest
```

### 3. Test Container

```bash
# Test endpoints
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/api/rides

# Check logs
docker logs wildrydes-container

# Follow logs
docker logs -f wildrydes-container
```

### 4. Verify Health Check

```bash
# The Dockerfile includes a health check
# View container status
docker ps

# Should show: healthy
```

## Advanced Docker Testing

### Interactive Shell

```bash
# Get shell access to running container
docker exec -it wildrydes-container sh
```

### Check Image Size

```bash
# View image layers and size
docker images wildrydes-app

# Inspect image
docker inspect wildrydes-app:latest
```

### Build with Build Args

```bash
# Build with custom arguments
docker build --build-arg NODE_ENV=production \
  -t wildrydes-app:v1.0.0 .
```

## Load Testing

### Using Apache Bench

```bash
# Install ab (comes with Apache)
# On macOS: brew install httpd

# Simple load test
ab -n 1000 -c 10 http://localhost:8080/

# Test specific endpoint
ab -n 5000 -c 50 http://localhost:8080/health
```

### Using Apache JMeter

```bash
# Create a test plan with:
# - 100 concurrent users
# - 1000 total requests
# - Ramp-up time: 60 seconds
# - Target: http://localhost:8080/
```

### Using hey (Simple HTTP Load Generator)

```bash
# Install: go install github.com/rakyll/hey@latest

# Run load test
hey -n 5000 -c 100 http://localhost:8080/
```

## Debugging

### View Environment Variables

```bash
# In running container
docker exec wildrydes-container env
```

### Monitor Resource Usage

```bash
# Monitor container resource usage
docker stats wildrydes-container

# Check memory usage
docker exec wildrydes-container ps aux
```

### Check Network

```bash
# Verify port mapping
docker port wildrydes-container

# Test from container
docker exec wildrydes-container curl http://localhost:8080/health
```

## Integration Testing

### Automated Tests

```bash
# Create test file: test.js
# Install testing framework:
npm install --save-dev jest supertest

# Run tests
npm test
```

### Health Check Validation

```bash
#!/bin/bash
# Script to validate health checks every 5 seconds

for i in {1..10}; do
    response=$(curl -s http://localhost:8080/health)
    echo "Check $i: $response"
    sleep 5
done
```

## Docker Push to ECR (After AWS Account Setup)

```bash
# Set variables
AWS_ACCOUNT_ID="your-account-id"
AWS_REGION="us-east-1"
REPOSITORY_NAME="wildrydes-app"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Tag image
docker tag wildrydes-app:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:latest

# Push image
docker push \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:latest
```

## Cleanup

```bash
# Stop container
docker stop wildrydes-container

# Remove container
docker rm wildrydes-container

# Remove image
docker rmi wildrydes-app:latest

# Remove all dangling images
docker image prune -f
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs wildrydes-container

# Inspect container
docker inspect wildrydes-container

# Check if port is already in use
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows
```

### Health Check Failing

```bash
# Test health check manually
docker exec wildrydes-container curl http://localhost:8080/health

# Check health check configuration in Dockerfile
docker inspect --format='{{json .HealthCheck}}' wildrydes-app:latest
```

### Performance Issues

```bash
# Check resource limits
docker inspect wildrydes-container | grep -A 20 Memory

# Monitor in real-time
docker stats wildrydes-container

# Check CPU usage
docker exec wildrydes-container top
```

---

For more information, see README.md and DEPLOYMENT_GUIDE.md
