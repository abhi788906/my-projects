# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "Video Upload Platform API"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-api"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Resource for uploads
resource "aws_api_gateway_resource" "uploads" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "uploads"
}

# API Gateway Resource for multipart
resource "aws_api_gateway_resource" "multipart" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "multipart"
}

# API Gateway Resource for multipart init
resource "aws_api_gateway_resource" "multipart_init" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.multipart.id
  path_part   = "init"
}

# API Gateway Resource for multipart complete
resource "aws_api_gateway_resource" "multipart_complete" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.multipart.id
  path_part   = "complete"
}

# API Gateway Method for video upload
resource "aws_api_gateway_method" "video_upload" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.uploads.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

# API Gateway Method for multipart init
resource "aws_api_gateway_method" "multipart_init" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.multipart_init.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

# API Gateway Method for multipart complete
resource "aws_api_gateway_method" "multipart_complete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.multipart_complete.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

# Lambda Integration for video upload
resource "aws_api_gateway_integration" "video_upload" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.video_upload.http_method
  
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.video_upload_lambda_invoke_arn
  
  timeout_milliseconds = 29000
}

# Lambda Integration for multipart init
resource "aws_api_gateway_integration" "multipart_init" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.multipart_init.id
  http_method = aws_api_gateway_method.multipart_init.http_method
  
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.multipart_init_lambda_invoke_arn
  
  timeout_milliseconds = 29000
}

# Lambda Integration for multipart complete
resource "aws_api_gateway_integration" "multipart_complete" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.multipart_complete.id
  http_method = aws_api_gateway_method.multipart_complete.http_method
  
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = var.multipart_complete_lambda_invoke_arn
  
  timeout_milliseconds = 29000
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "${var.project_name}-${var.environment}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  provider_arns = [var.cognito_user_pool_arn]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.video_upload,
    aws_api_gateway_integration.multipart_init,
    aws_api_gateway_integration.multipart_complete,
    aws_api_gateway_integration.options,
    aws_api_gateway_integration.uploads_options
  ]
  
  rest_api_id = aws_api_gateway_rest_api.main.id
  
  lifecycle {
    create_before_destroy = true
  }
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.video_upload,
      aws_api_gateway_method.multipart_init,
      aws_api_gateway_method.multipart_complete,
      aws_api_gateway_method.uploads_options
    ]))
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-stage"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "video_upload_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.video_upload_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "multipart_init_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.multipart_init_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "multipart_complete_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.multipart_complete_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway Method Response for CORS (for video upload)
resource "aws_api_gateway_method_response" "video_upload_cors" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.video_upload.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# CORS Method Responses for multipart methods
resource "aws_api_gateway_method_response" "multipart_init_cors" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.multipart_init.id
  http_method = aws_api_gateway_method.multipart_init.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_method_response" "multipart_complete_cors" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.multipart_complete.id
  http_method = aws_api_gateway_method.multipart_complete.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# OPTIONS method for uploads resource CORS preflight
resource "aws_api_gateway_method" "uploads_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.uploads.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "uploads_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.uploads_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration" "uploads_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.uploads_options.http_method
  
  type = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "uploads_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.uploads.id
  http_method = aws_api_gateway_method.uploads_options.http_method
  status_code = aws_api_gateway_method_response.uploads_options.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
  }
}

# OPTIONS method for root CORS preflight
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.options.http_method
  
  type = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
  }
}
