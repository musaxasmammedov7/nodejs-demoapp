###############################################################################
# Secrets from AWS Secrets Manager
# Secrets are NEVER stored in git. Terraform reads them at runtime from AWS.
# To create/update the secret manually:
#
#   aws secretsmanager create-secret \
#     --name nodejs-demoapp/notification-email \
#     --secret-string "your@email.com" \
#     --region us-east-1
#
#   aws secretsmanager update-secret \
#     --secret-id nodejs-demoapp/notification-email \
#     --secret-string "new@email.com" \
#     --region us-east-1
###############################################################################

data "aws_secretsmanager_secret" "notification_email" {
  name = "${var.project_name}-${var.environment}-notification-email"
}

data "aws_secretsmanager_secret_version" "notification_email" {
  secret_id = data.aws_secretsmanager_secret.notification_email.id
}

locals {
  notification_email = data.aws_secretsmanager_secret_version.notification_email.secret_string
}