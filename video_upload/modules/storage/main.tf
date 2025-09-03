# S3 Bucket for video storage with Well-Architected best practices
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  
  tags = {
    Name = "${var.project_name}-${var.environment}-video-storage"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  count  = var.versioning ? 1 : 0
  bucket = aws_s3_bucket.main.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.encryption.enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption.algorithm
      kms_master_key_id = var.encryption.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  count  = var.block_public_access ? 1 : 0
  bucket = aws_s3_bucket.main.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.lifecycle_config.enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id
  
  rule {
    id     = "video-lifecycle-policy"
    status = "Enabled"
    
    filter {
      prefix = "uploads/"
    }
    
    # Transition to IA after 30 days
    transition {
      days          = var.lifecycle_config.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }
    
    # Transition to Glacier after 90 days
    transition {
      days          = var.lifecycle_config.transition_to_glacier_days
      storage_class = "GLACIER"
    }
    
    # Delete incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = var.multipart_upload.abort_incomplete_multipart_upload_days
    }
    
    # Expire objects after 7 years (2555 days)
    expiration {
      days = var.lifecycle_config.expiration_days
    }
  }
}

# S3 Bucket Policy for secure access
resource "aws_s3_bucket_policy" "main" {
  count  = var.access_control == "private" ? 1 : 0
  bucket = aws_s3_bucket.main.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid    = "DenyIncorrectEncryptionHeader"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = var.encryption.kms_key_id
          }
        }
      }
    ]
  })
}

# S3 Bucket CORS Configuration for multipart uploads
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "x-amz-multipart-upload-id"]
    max_age_seconds = 3000
  }
}

# S3 Bucket Notification Configuration
# Temporarily disabled until Lambda functions are fully configured
# resource "aws_s3_bucket_notification" "main" {
#   bucket = aws_s3_bucket.main.id
#   
#   # Lambda function notification for video processing
#   lambda_function {
#     lambda_function_arn = var.lambda_function_arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = "uploads/"
#     filter_suffix       = ".mp4"
#   }
#   
#   depends_on = [aws_lambda_permission.s3_notification]
# }

# Lambda permission for S3 notifications
# resource "aws_lambda_permission" "s3_notification" {
#   statement_id  = "AllowS3Invoke"
#   action        = "lambda:InvokeFunction"
#   function_name = var.lambda_function_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = aws_s3_bucket.main.arn
# }

# CloudWatch Log Group for S3 access logs
resource "aws_cloudwatch_log_group" "s3_access" {
  name              = "/aws/s3/${var.project_name}-${var.environment}"
  retention_in_days = 30
  
  tags = {
    Name = "${var.project_name}-${var.environment}-s3-access-logs"
  }
}

# S3 Bucket Access Logging
resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id
  
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "logs/"
}

# S3 Bucket for access logs
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.bucket_name}-access-logs"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-access-logs"
  }
}

# Access logs bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Access logs bucket public access block
resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
