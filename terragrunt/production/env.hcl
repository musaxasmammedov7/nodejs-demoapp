# Production Environment Configuration
# This file is referenced by all production modules via read_terragrunt_config()

locals {
  aws_region   = "us-east-1"
  environment  = "production"
  account_id   = "012345678901"

  # VPC Settings
  vpc_cidr           = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = ["10.10.3.0/24", "10.10.4.0/24"]

  # EC2 Settings
  instance_type    = "t3.small"
  key_name         = ""
  min_size         = 2
  max_size         = 6
  desired_capacity = 3

  # ALB Settings
  health_check_path = "/"

  # Scaling Settings
  cpu_target_value = 65

  # Notification Settings
  notification_email = ""
}
