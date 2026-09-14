# Load Testing Environment Configuration
# This file is referenced by all load-testing modules via read_terragrunt_config()
# Purpose: Dedicated environment for performance/load testing by the QA team

locals {
  aws_region   = "us-east-1"
  environment  = "load-testing"
  account_id   = "012345678901"

  # VPC Settings
  vpc_cidr           = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.3.0/24", "10.20.4.0/24"]

  # EC2 Settings - Larger instances for load testing
  instance_type    = "t3.medium"
  key_name         = ""
  min_size         = 2
  max_size         = 10
  desired_capacity = 3

  # ALB Settings
  health_check_path = "/"

  # Scaling Settings - More aggressive scaling for load tests
  cpu_target_value = 60

  # Notification Settings
  notification_email = ""
}
