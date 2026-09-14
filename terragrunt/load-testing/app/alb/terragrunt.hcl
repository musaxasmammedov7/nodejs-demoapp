# ALB Module - Load Testing Environment
# Creates Application Load Balancer, Target Group, and Listener

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

dependency "vpc" {
  config_path = "../../../vpc"
}

dependency "sg" {
  config_path = "../sg"
}

terraform {
  source = "../../../modules//alb"
}

inputs = {
  aws_region       = local.env_vars.locals.aws_region
  environment      = local.env_vars.locals.environment
  public_subnet_ids = dependency.vpc.outputs.public_subnet_ids
  alb_security_group_id = dependency.sg.outputs.alb_security_group_id
  health_check_path = local.env_vars.locals.health_check_path
}
