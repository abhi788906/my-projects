# Lambda function for video upload processing
resource "aws_lambda_function" "video_upload" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.env_name}-video-upload"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrency > 0 ? var.reserved_concurrency : null
  
  environment {
    variables = merge(var.environment, {
      BUCKET_NAME = var.s3_bucket_name
      LOG_LEVEL   = "INFO"
    })
  }
  
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }
  
  tags = {
    Name = "${var.project_name}-${var.env_name}-video-upload"
  }
  
  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

# Lambda function for multipart upload initiation
resource "aws_lambda_function" "multipart_init" {
  filename         = data.archive_file.multipart_zip.output_path
  function_name    = "${var.project_name}-${var.env_name}-multipart-init"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrency > 0 ? var.reserved_concurrency : null
  
  environment {
    variables = merge(var.environment, {
      BUCKET_NAME = var.s3_bucket_name
      LOG_LEVEL   = "INFO"
      KMS_KEY_ID  = var.kms_key_id
    })
  }
  
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }
  
  tags = {
    Name = "${var.project_name}-${var.env_name}-multipart-init"
  }
  
  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

# Lambda function for multipart upload completion
resource "aws_lambda_function" "multipart_complete" {
  filename         = data.archive_file.complete_zip.output_path
  function_name    = "${var.project_name}-${var.env_name}-multipart-complete"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrency > 0 ? var.reserved_concurrency : null
  
  environment {
    variables = merge(var.environment, {
      BUCKET_NAME = var.s3_bucket_name
      LOG_LEVEL   = "INFO"
      KMS_KEY_ID  = var.kms_key_id
    })
  }
  
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }
  
  tags = {
    Name = "${var.project_name}-${var.env_name}-multipart-complete"
  }
  
  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.env_name}-lambda-exec-role"
  
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
  
  tags = {
    Name = "${var.project_name}-${var.env_name}-lambda-exec-role"
  }
}

# IAM policy for Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# IAM policy for Lambda logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM policy for S3 access
resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.project_name}-${var.env_name}-lambda-s3-policy"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM policy for KMS access
resource "aws_iam_role_policy" "lambda_kms" {
  name = "${var.project_name}-${var.env_name}-lambda-kms-policy"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM policy for CloudWatch metrics
resource "aws_iam_role_policy" "lambda_cloudwatch" {
  name = "${var.project_name}-${var.env_name}-lambda-cloudwatch-policy"
  role = aws_iam_role.lambda_exec.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.env_name}"
  retention_in_days = 30
  
  tags = {
    Name = "${var.project_name}-${var.env_name}-lambda-logs"
  }
}

# Data source for Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_functions/video_upload.zip"
  source_dir  = "${path.module}/lambda_functions/video_upload"
}

data "archive_file" "multipart_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_functions/multipart_init.zip"
  source_dir  = "${path.module}/lambda_functions/multipart_init"
}

data "archive_file" "complete_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_functions/multipart_complete.zip"
  source_dir  = "${path.module}/lambda_functions/multipart_complete"
}
