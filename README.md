# Week 3 Task 1: Node.js Demo App Infrastructure

## Overview
This Terraform configuration sets up AWS infrastructure for hosting the [nodejs-demoapp](https://github.com/benc-uk/nodejs-demoapp) application with Auto Scaling, Load Balancing, and monitoring.

## Architecture
- **VPC**: Multi-AZ with public and private subnets
- **ALB**: Application Load Balancer for traffic distribution
- **ASG**: Auto Scaling Group with Launch Template
- **EC2**: Docker-based deployment via user data
- **Monitoring**: CloudWatch Alarms and Dashboard
- **Notifications**: SNS for scaling events

## Directory Structure
```
week3_task1/
├── infrastructure/
│   ├── common/          # Shared Terraform modules
│   │   ├── main.tf      # Provider and data sources
│   │   ├── variables.tf # Input variables
│   │   ├── outputs.tf   # Output values
│   │   ├── network.tf   # VPC, subnets, security groups
│   │   ├── ec2.tf       # ASG, Launch Template, ALB
│   │   ├── cloudwatch.tf # Alarms and dashboard
│   │   └── sns.tf       # Notification topics
│   ├── env/             # Environment-specific variables
│   │   ├── dev.tfvars
│   │   └── production.tfvars
│   ├── dev/             # Development environment
│   └── production/      # Production environment
├── user_data/
│   └── user_data.sh     # EC2 initialization script
└── artillery/
    └── load-test.yml    # Load testing configuration
```

## Deployment

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0 installed
- S3 bucket for state storage (create manually first)

### Initialize and Deploy
```bash
# For development
cd infrastructure/dev
terraform init
terraform plan -var-file="../env/dev.tfvars"
terraform apply -var-file="../env/dev.tfvars"

# For production
cd infrastructure/production
terraform init
terraform plan -var-file="../env/production.tfvars"
terraform apply -var-file="../env/production.tfvars"
```

### Access the Application
After deployment, get the ALB DNS name:
```bash
terraform output application_url
```

## Features
- **Auto Scaling**: CPU-based scaling with configurable thresholds
- **Health Checks**: ALB monitors instance health
- **Rolling Deployments**: Instance refresh on template changes
- **Monitoring**: CloudWatch dashboard and alarms
- **Notifications**: Email alerts for scaling events

## Load Testing
```bash
export TARGET_URL=<ALB_DNS_NAME>
artillery run artillery/load-test.yml
```
