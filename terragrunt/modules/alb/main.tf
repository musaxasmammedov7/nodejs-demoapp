###############################################################################
# ALB Module
# Creates: Application Load Balancer, Target Group, Listener
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/"
}

locals {
  name_prefix = "nodejs-demoapp-${var.environment}"
}

###############################################################################
# Application Load Balancer
###############################################################################
resource "aws_lb" "app" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${local.name_prefix}-public-alb"
  }
}

###############################################################################
# Target Group
###############################################################################
resource "aws_lb_target_group" "app" {
  name     = "${local.name_prefix}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = split("/", var.public_subnet_ids[0])[0]

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    matcher             = "200"
  }

  tags = {
    Name = "${local.name_prefix}-target-group"
  }
}

###############################################################################
# ALB Listener
###############################################################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${local.name_prefix}-http-listener"
  }
}

###############################################################################
# Outputs
###############################################################################
output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "alb_arn" {
  value = aws_lb.app.arn
}

output "alb_arn_suffix" {
  value = aws_lb.app.arn_suffix
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
