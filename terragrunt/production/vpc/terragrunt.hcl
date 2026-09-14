# VPC Module - Production Environment
# This module creates VPC, subnets, internet gateway, NAT gateway, and route tables

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

terraform {
  source = "../../modules//vpc"
}

inputs = {
  aws_region          = local.env_vars.locals.aws_region
  environment         = local.env_vars.locals.environment
  vpc_cidr            = local.env_vars.locals.vpc_cidr
  public_subnet_cidrs  = local.env_vars.locals.public_subnet_cidrs
  private_subnet_cidrs = local.env_vars.locals.private_subnet_cidrs
}
