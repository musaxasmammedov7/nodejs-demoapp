###############################################################################
# SNS Topic for Scaling Notifications
###############################################################################
resource "aws_sns_topic" "scaling_notifications" {
  name = "${local.name_prefix}-scaling-notifications"

  tags = {
    Name = "${local.name_prefix}-scaling-sns-topic"
  }
}

###############################################################################
# SNS Topic Policy
###############################################################################
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
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.name_prefix}-asg"
          }
        }
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

data "aws_caller_identity" "current" {}

###############################################################################
# Email Subscription (only if email provided)
###############################################################################
resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.scaling_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

###############################################################################
# Auto Scaling Group Notification Configuration
###############################################################################
resource "aws_autoscaling_notification" "app_notifications" {
  group_names = [aws_autoscaling_group.app.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.scaling_notifications.arn
}
