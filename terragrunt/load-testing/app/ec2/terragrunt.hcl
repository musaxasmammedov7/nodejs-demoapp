# EC2/Autoscaling Module - Load Testing Environment
# Creates Launch Template and Auto Scaling Group

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

dependency "vpc" {
  config_path = "../../vpc"
}

dependency "sg" {
  config_path = "../sg"
}

dependency "alb" {
  config_path = "../alb"
}

terraform {
  source = "../../../modules//ec2"
}

inputs = {
  aws_region          = local.env_vars.locals.aws_region
  environment         = local.env_vars.locals.environment
  instance_type       = local.env_vars.locals.instance_type
  key_name            = local.env_vars.locals.key_name
  min_size            = local.env_vars.locals.min_size
  max_size            = local.env_vars.locals.max_size
  desired_capacity    = local.env_vars.locals.desired_capacity
  private_subnet_ids  = dependency.vpc.outputs.private_subnet_ids
  ec2_security_group_id = dependency.sg.outputs.ec2_security_group_id
  target_group_arn    = dependency.alb.outputs.target_group_arn
}
