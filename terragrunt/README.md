# Task 2: Infrastructure Provisioning with Terragrunt

## Overview

This project uses **Terragrunt** to manage multiple AWS environments (dev, production, load-testing) with maximum code reuse following the **DRY (Don't Repeat Yourself)** principle.

## What is Terragrunt?

Terragrunt is a thin wrapper for Terraform that provides:
- **DRY configuration**: Write shared settings once, use everywhere
- **Remote state management**: Automatic S3 backend configuration
- **Dependency management**: Control deployment order between modules
- **Environment isolation**: Separate state files per environment

## Project Structure

```
terragrunt/
├── terragrunt.hcl              # Root config (shared across ALL environments)
├── infracost.yml               # Infracost configuration for cost estimation
├── cost-estimation.sh          # Script to run plan + cost estimate
│
├── modules/                    # Reusable Terraform modules
│   ├── vpc/main.tf            # VPC, subnets, NAT gateway
│   ├── sg/main.tf             # Security groups
│   ├── alb/main.tf            # Load balancer, target group
│   ├── ec2/main.tf            # Launch template, autoscaling
│   └── cloudwatch/main.tf     # Alarms, dashboard, SNS
│
├── env/                        # Environment variable files
│   ├── dev.tfvars
│   ├── production.tfvars
│   └── load-testing.tfvars
│
├── dev/                        # Development environment
│   ├── env.hcl                # Dev-specific variables
│   ├── vpc/terragrunt.hcl     # VPC module config
│   └── app/
│       ├── sg/terragrunt.hcl
│       ├── alb/terragrunt.hcl
│       ├── ec2/terragrunt.hcl
│       └── cloudwatch/terragrunt.hcl
│
├── production/                 # Production environment
│   ├── env.hcl
│   ├── vpc/terragrunt.hcl
│   └── app/...
│
└── load-testing/               # Load testing environment (NEW)
    ├── env.hcl
    ├── vpc/terragrunt.hcl
    └── app/...
```

## How It Works

### 1. Root `terragrunt.hcl`

This file is the **single source of truth** for:
- AWS provider version
- S3 backend configuration
- Common inputs

Every child `terragrunt.hcl` automatically inherits these settings.

### 2. Environment `env.hcl` Files

Each environment has its own `env.hcl` that defines:
- AWS region
- VPC CIDR ranges
- Instance types
- Scaling parameters
- Notification settings

Modules read these using:
```hcl
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}
```

### 3. Dependency Management

Terragrunt uses `dependency` blocks to manage module relationships:

```hcl
dependency "vpc" {
  config_path = "../../vpc"
}

dependency "sg" {
  config_path = "../sg"
}

inputs = {
  vpc_id              = dependency.vpc.outputs.vpc_id
  security_group_id   = dependency.sg.outputs.ec2_security_group_id
}
```

This ensures:
- VPC is created before security groups
- Security groups are created before ALB
- ALB is created before EC2/Autoscaling

### 4. Terraform Modules

Reusable modules in `modules/` directory:
- **vpc**: VPC, subnets, internet gateway, NAT gateway
- **sg**: ALB and EC2 security groups
- **alb**: Load balancer, target group, listener
- **ec2**: IAM role, launch template, autoscaling group
- **cloudwatch**: Alarms, dashboard, SNS notifications

## Usage

### Prerequisites

```bash
# Install Terraform
brew install terraform

# Install Terragrunt
brew install terragrunt

# Install Infracost (optional, for cost estimation)
brew install infracost
```

### Deploy to Dev

```bash
cd terragrunt/dev/vpc
terragrunt apply

cd ../app/sg
terragrunt apply

cd ../alb
terragrunt apply

cd ../ec2
terragrunt apply

cd ../cloudwatch
terragrunt apply
```

### Deploy to Production

```bash
cd terragrunt/production/vpc
terragrunt apply

cd ../app/sg
terragrunt apply

# ... and so on
```

### Deploy to Load Testing

```bash
cd terragrunt/load-testing/vpc
terragrunt apply

# ... and so on
```

### Run All Environments at Once

```bash
# Using Terragrunt run-all
cd terragrunt/dev
terragrunt run-all apply

cd terragrunt/production
terragrunt run-all apply

cd terragrunt/load-testing
terragrunt run-all apply
```

## Cost Estimation with Infracost

### Setup

```bash
# Sign up for free at infracost.io
infracost auth login

# Configure API key
export INFRACOST_API_KEY="your-api-key"
```

### Run Cost Estimation

```bash
# Using the provided script
cd terragrunt
./cost-estimation.sh dev
./cost-estimation.sh production
./cost-estimation.sh load-testing

# Or run infracost directly
cd terragrunt
infracost breakdown --config infracost.yml
```

### CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
- name: Run Infracost
  uses: infracost/actions/setup@v2
  with:
    api-key: ${{ secrets.INFRACOST_API_KEY }}

- name: Generate cost estimate
  run: |
    cd terragrunt
    infracost breakdown --config infracost.yml --format json > cost-estimate.json
```

## Environment Comparison

| Setting | Dev | Production | Load Testing |
|---------|-----|------------|--------------|
| Instance Type | t3.micro | t3.small | t3.medium |
| Min Instances | 1 | 2 | 2 |
| Max Instances | 3 | 6 | 10 |
| Desired Instances | 2 | 3 | 3 |
| CPU Target | 70% | 65% | 60% |
| VPC CIDR | 10.0.0.0/16 | 10.10.0.0/16 | 10.20.0.0/16 |

## Key Concepts

### DRY Principle

Instead of duplicating Terraform code for each environment, Terragrunt allows us to:
1. Write each module ONCE in `modules/`
2. Configure each environment ONCE in `env.hcl`
3. Reference modules in `terragrunt.hcl` with environment-specific inputs

### State Isolation

Each environment gets its own state file:
- `dev/vpc/terraform.tfstate`
- `production/vpc/terraform.tfstate`
- `load-testing/vpc/terraform.tfstate`

This prevents changes in one environment from affecting others.

### Dependency Graph

```
VPC → Security Groups → ALB → EC2/Autoscaling → CloudWatch
```

Terragrunt automatically handles this ordering.
