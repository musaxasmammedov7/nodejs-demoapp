# Security Groups Module - Load Testing Environment
# Creates ALB and EC2 security groups

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

dependency "vpc" {
  config_path = "../../vpc"
}

terraform {
  source = "../../../modules//sg"
}

inputs = {
  aws_region   = local.env_vars.locals.aws_region
  environment  = local.env_vars.locals.environment
  vpc_id       = dependency.vpc.outputs.vpc_id
}
