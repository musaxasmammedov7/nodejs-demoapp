# Development Environment Configuration
environment         = "dev"
aws_region          = "us-east-1"
project_name        = "nodejs-demoapp"

# Network Configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# EC2 Configuration
instance_type       = "t3.micro"
key_name            = ""
min_size            = 1
max_size            = 3
desired_capacity    = 2

# Scaling Configuration
cpu_target_value    = 70
health_check_path   = "/"
