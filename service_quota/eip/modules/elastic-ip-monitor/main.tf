# =============================================================================
# Elastic IP Monitor Module - Main Configuration
# =============================================================================

# Lambda Layer
resource "aws_lambda_layer_version" "elastic_ip_monitor" {
  filename            = var.lambda_layer_zip_path
  layer_name          = "${var.module_name}-elastic-ip-monitor-layer"
  compatible_runtimes = var.lambda_runtime
  description         = "Dependencies for Elastic IP quota monitoring Lambda function"
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.module_name}-lambda-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda function
resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.module_name}-lambda-custom-policy"
  role = aws_iam_role.lambda_execution.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAddresses",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "service-quotas:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn != null ? [var.sns_topic_arn] : ["*"]
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "elastic_ip_monitor" {
  filename         = var.lambda_function_zip_path
  function_name    = "${var.module_name}-elastic-ip-monitor"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = var.lambda_runtime[0]
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  layers = [aws_lambda_layer_version.elastic_ip_monitor.arn]
  
  environment {
    variables = {
      LOG_LEVEL              = var.log_level
      REGION                 = var.aws_region
      QUOTA_CODE            = var.quota_code
      SERVICE_CODE          = var.service_code
      USAGE_THRESHOLD      = var.usage_threshold
      QUOTA_INCREMENT      = var.quota_increment
      ENABLE_QUOTA_INCREASE = var.enable_quota_increase
      SNS_TOPIC_ARN        = var.sns_topic_arn
    }
  }
  
  tags = var.tags
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "elastic_ip_allocation" {
  name        = "${var.module_name}-elastic-ip-allocation-rule"
  description = "Triggers Lambda function when Elastic IP is allocated"
  
  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["AllocateAddress"]
    }
  })
  
  tags = var.tags
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.elastic_ip_allocation.name
  target_id = "ElasticIPMonitorLambda"
  arn       = aws_lambda_function.elastic_ip_monitor.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.elastic_ip_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.elastic_ip_allocation.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.elastic_ip_monitor.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days
  
  tags = var.tags
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "elastic_ip_monitoring" {
  dashboard_name = "${var.module_name}-elastic-ip-monitoring"
  
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
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.elastic_ip_monitor.function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Function Metrics"
        }
      }
    ]
  })
}
