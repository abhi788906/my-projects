# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-user-pool"
  
  # Password policy
  password_policy {
    minimum_length    = var.password_policy.minimum_length
    require_uppercase = var.password_policy.require_uppercase
    require_lowercase = var.password_policy.require_lowercase
    require_numbers   = var.password_policy.require_numbers
    require_symbols   = var.password_policy.require_symbols
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
  }
  
  # MFA configuration
  mfa_configuration = var.mfa_configuration.enabled ? "ON" : "OFF"
  
  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration.enabled ? [1] : []
    content {
      enabled = true
    }
  }
  
  # Advanced security features
  
  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }
  
  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  
  # Username attributes
  username_attributes = ["email"]
  
  # Auto verified attributes
  auto_verified_attributes = ["email"]
  
  # Verification message template
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your verification code"
    email_message        = "Your verification code is {####}"
  }
  
  # Admin create user config
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  
  # Lambda triggers
  dynamic "lambda_config" {
    for_each = var.lambda_triggers.enabled ? [1] : []
    content {
      pre_authentication  = var.lambda_triggers.pre_authentication_arn
      post_authentication = var.lambda_triggers.post_authentication_arn
      pre_token_generation = var.lambda_triggers.pre_token_generation_arn
    }
  }
  
  # Device tracking
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }
  

  
  tags = {
    Name        = "${var.project_name}-${var.environment}-user-pool"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-${var.environment}-client"
  user_pool_id = aws_cognito_user_pool.main.id
  
  # Client settings
  generate_secret = false
  
  # OAuth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  
  # Callback URLs
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls
  
  # Allowed OAuth scopes
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile"
  ]
  
  # Allowed OAuth flows
  allowed_oauth_flows = [
    "code",
    "implicit"
  ]
  
  # Supported identity providers
  supported_identity_providers = ["COGNITO"]
  
  # Token validity
  access_token_validity  = var.token_validity.access_token_hours
  id_token_validity      = var.token_validity.id_token_hours
  refresh_token_validity = var.token_validity.refresh_token_days
  
  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"
  
  # Enable token revocation
  enable_token_revocation = true
  

}

# Cognito Identity Pool
resource "aws_cognito_identity_pool" "main" {
  identity_pool_name = "${var.project_name}-${var.environment}-identity-pool"
  
  # Allow unauthenticated identities (for guest access)
  allow_unauthenticated_identities = var.allow_unauthenticated_identities
  
  # Cognito identity providers
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }
  
  # Supported login providers
  supported_login_providers = var.supported_login_providers
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-identity-pool"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for authenticated users
resource "aws_iam_role" "authenticated" {
  name = "${var.project_name}-${var.environment}-cognito-authenticated-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-cognito-authenticated-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for unauthenticated users
resource "aws_iam_role" "unauthenticated" {
  count = var.allow_unauthenticated_identities ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-cognito-unauthenticated-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-cognito-unauthenticated-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role Policy for authenticated users
resource "aws_iam_role_policy" "authenticated" {
  name = "${var.project_name}-${var.environment}-cognito-authenticated-policy"
  role = aws_iam_role.authenticated.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.s3_bucket_arn}/uploads/${aws_cognito_identity_pool.main.id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          var.video_upload_lambda_arn,
          var.multipart_init_lambda_arn,
          var.multipart_complete_lambda_arn
        ]
      }
    ]
  })
}

# IAM Role Policy for unauthenticated users
resource "aws_iam_role_policy" "unauthenticated" {
  count = var.allow_unauthenticated_identities ? 1 : 0
  
  name = "${var.project_name}-${var.environment}-cognito-unauthenticated-policy"
  role = aws_iam_role.unauthenticated[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${var.s3_bucket_arn}/public/*"
        ]
      }
    ]
  })
}

# Cognito Identity Pool Role Attachment
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id
  
  roles = {
    authenticated   = aws_iam_role.authenticated.arn
    unauthenticated = var.allow_unauthenticated_identities ? aws_iam_role.unauthenticated[0].arn : null
  }
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Cognito User Pool Group for admins
resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrator users"
  precedence   = 1
  
  role_arn = aws_iam_role.authenticated.arn
}

# Cognito User Pool Group for regular users
resource "aws_cognito_user_group" "user" {
  name         = "user"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Regular users"
  precedence   = 2
  
  role_arn = aws_iam_role.authenticated.arn
}
