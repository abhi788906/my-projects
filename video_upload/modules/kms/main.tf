# KMS Key for encryption (Well-Architected Security Pillar)
resource "aws_kms_key" "main" {
  count                   = var.enabled ? 1 : 0
  description             = "KMS key for ${var.project_name}-${var.environment} encryption"
  deletion_window_in_days = var.deletion_window
  enable_key_rotation     = var.key_rotation
  
  # Key policy for least privilege access
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      {
        Sid    = "Allow Lambda Functions"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService": "lambda.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow S3"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService": "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-${var.environment}-kms-key"
  }
}

# KMS Key Alias
resource "aws_kms_alias" "main" {
  count         = var.enabled ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main[0].id
}

# Data sources for current account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudWatch Log Group for KMS key usage
resource "aws_cloudwatch_log_group" "kms" {
  count             = var.enabled ? 1 : 0
  name              = "/aws/kms/${var.project_name}-${var.environment}"
  retention_in_days = 30
  
  tags = {
    Name = "${var.project_name}-${var.environment}-kms-logs"
  }
}

# CloudWatch Alarm for KMS key usage
resource "aws_cloudwatch_metric_alarm" "kms_usage" {
  count               = var.enabled ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-kms-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfRequests"
  namespace           = "AWS/KMS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "KMS key usage monitoring"
  
  dimensions = {
    KeyId = aws_kms_key.main[0].id
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-kms-usage-alarm"
  }
}
