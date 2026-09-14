# Dev Environment Configuration
# This file is referenced by all dev modules via read_terragrunt_config()

locals {
  aws_region   = "us-east-1"
  environment  = "dev"
  account_id   = "012345678901"

  # VPC Settings
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

  # EC2 Settings
  instance_type    = "t3.micro"
  key_name         = ""
  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  # ALB Settings
  health_check_path = "/"

  # Scaling Settings
  cpu_target_value = 70

  # Notification Settings
  notification_email = ""
}
