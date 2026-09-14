# CloudWatch Module - Dev Environment
# Creates CloudWatch Alarms, Dashboard, and SNS Notifications

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
}

dependency "ec2" {
  config_path = "../ec2"
}

dependency "alb" {
  config_path = "../alb"
}

terraform {
  source = "../../../modules//cloudwatch"
}

inputs = {
  aws_region            = local.env_vars.locals.aws_region
  environment           = local.env_vars.locals.environment
  cpu_target_value      = local.env_vars.locals.cpu_target_value
  notification_email    = local.env_vars.locals.notification_email
  autoscaling_group_name = dependency.ec2.outputs.autoscaling_group_name
  alb_arn_suffix        = dependency.alb.outputs.alb_arn_suffix
}
