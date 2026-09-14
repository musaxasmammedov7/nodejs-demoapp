###############################################################################
# VPC Outputs
###############################################################################
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

###############################################################################
# Subnet Outputs
###############################################################################
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

###############################################################################
# Load Balancer Outputs
###############################################################################
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app.arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.app.zone_id
}

###############################################################################
# Target Group Outputs
###############################################################################
output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.app.arn
}

output "target_group_name" {
  description = "Name of the Target Group"
  value       = aws_lb_target_group.app.name
}

###############################################################################
# Auto Scaling Group Outputs
###############################################################################
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

###############################################################################
# Security Group Outputs
###############################################################################
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

###############################################################################
# SNS Outputs
###############################################################################
output "sns_topic_arn" {
  description = "ARN of the SNS topic for scaling notifications"
  value       = aws_sns_topic.scaling_notifications.arn
}

###############################################################################
# CloudWatch Outputs
###############################################################################
output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.app.dashboard_name
}

###############################################################################
# Application URL
###############################################################################
output "application_url" {
  description = "URL of the application"
  value       = "http://${aws_lb.app.dns_name}"
}
