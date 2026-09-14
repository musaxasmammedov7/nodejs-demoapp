###############################################################################
# CloudWatch Module
# Creates: Alarms, Dashboard, SNS Topic, Scaling Policies
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cpu_target_value" {
  description = "Target CPU utilization for scaling"
  type        = number
  default     = 70
}

variable "notification_email" {
  description = "Email for scaling notifications"
  type        = string
  default     = ""
}

variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "nodejs-demoapp-${var.environment}"
}

###############################################################################
# SNS Topic for Scaling Notifications
###############################################################################
resource "aws_sns_topic" "scaling_notifications" {
  name = "${local.name_prefix}-scaling-notifications"

  tags = {
    Name = "${local.name_prefix}-scaling-sns-topic"
  }
}

resource "aws_sns_topic_policy" "scaling_notifications" {
  arn = aws_sns_topic.scaling_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAutoScalingPublish"
        Effect    = "Allow"
        Principal = { Service = "autoscaling.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.scaling_notifications.arn
      },
      {
        Sid       = "AllowCloudWatchPublish"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.scaling_notifications.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.scaling_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

###############################################################################
# CloudWatch Alarms
###############################################################################
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  alarm_description   = "CPU exceeds ${var.cpu_target_value}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_target_value
  alarm_actions       = [aws_sns_topic.scaling_notifications.arn]
  ok_actions          = [aws_sns_topic.scaling_notifications.arn]

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  tags = {
    Name = "${local.name_prefix}-high-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  alarm_description   = "ALB returns 5XX errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [aws_sns_topic.scaling_notifications.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "${local.name_prefix}-alb-5xx-alarm"
  }
}

###############################################################################
# Scaling Policies
###############################################################################
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = var.autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

###############################################################################
# CloudWatch Dashboard
###############################################################################
resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.autoscaling_group_name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Request Count"
        }
      }
    ]
  })
}

###############################################################################
# Outputs
###############################################################################
output "sns_topic_arn" {
  value = aws_sns_topic.scaling_notifications.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.app.dashboard_name
}
