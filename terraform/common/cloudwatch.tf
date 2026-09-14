###############################################################################
# CloudWatch Alarms for Auto Scaling
###############################################################################
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  alarm_description   = "Alarm when CPU exceeds ${var.cpu_target_value}%"
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
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name = "${local.name_prefix}-high-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${local.name_prefix}-low-cpu"
  alarm_description   = "Alarm when CPU drops below 30%"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_sns_topic.scaling_notifications.arn]
  ok_actions          = [aws_sns_topic.scaling_notifications.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name = "${local.name_prefix}-low-cpu-alarm"
  }
}

###############################################################################
# ALB Metrics - 5XX Errors
###############################################################################
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  alarm_description   = "Alarm when ALB returns 5XX errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [aws_sns_topic.scaling_notifications.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }

  tags = {
    Name = "${local.name_prefix}-alb-5xx-alarm"
  }
}

###############################################################################
# ALB Metrics - Request Count
###############################################################################
resource "aws_cloudwatch_metric_alarm" "alb_request_count" {
  alarm_name          = "${local.name_prefix}-alb-high-request-count"
  alarm_description   = "Alarm when ALB request count exceeds threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_actions       = [aws_sns_topic.scaling_notifications.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }

  tags = {
    Name = "${local.name_prefix}-alb-request-count-alarm"
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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.app.name]
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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB Request Count"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB 5XX Errors"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.app.name],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.app.name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Auto Scaling Group Capacity"
        }
      }
    ]
  })
}
