data "aws_caller_identity" "current" {}

# Zip the Code File
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/key_rotater.py"
  output_path = "${path.module}/key_rotater.zip"
}

# VPC Configuration

# Lambda Configuration
resource "aws_lambda_function" "access_key_rotater" {
  function_name = "${var.function_name}"  # Replace with your desired function name
  role          = aws_iam_role.key_rotater_role.arn
  handler       = "key_rotater.lambda_handler"            # Replace with the appropriate handler for your code
  runtime       = "python3.8"               # Replace with the desired runtime
  timeout  = 300

  vpc_config {
  subnet_ids = [var.subnet_id]
  security_group_ids = [aws_security_group.lambda_sg.id]
}

  environment {
    variables = {
      KEY_AGE = "${var.max_key_age}"
      ADMIN_EMAIL = "${var.admin_email}"
      ADMIN_USERNAME = "${var.admin_username}"
      AWS_ACCOUNT_ID = "${data.aws_caller_identity.current.account_id}"
      ROLE_ARN = "${aws_iam_role.key_rotater_role.arn}"
      DELETE_KEY = "${var.expire_key_age}"
      ADMIN_GROUP  = "${var.admin_group_name}"
      TAG_KEY = "${var.tag_key}"
      TAG_VALUE = "${var.tag_value}"
    }
  }

  filename = "${data.archive_file.lambda.output_path}"  # Replace with the path to your Lambda function code zip file
  source_code_hash = data.archive_file.lambda.output_base64sha256   # Replace with the path to your Lambda function code zip file
}

# Trust Relationship Policy for Lambda role
data "aws_iam_policy_document" "access_key_rotater_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "key_rotater_role" {
  name = "${var.function_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.access_key_rotater_role_policy.json}"
  managed_policy_arns = [aws_iam_policy.access_key_rotater_role_policy.arn]
}

# IAM Policy for the function
resource "aws_iam_policy" "access_key_rotater_role_policy" {
  name = "access_key_rotater_function_role_policy"

    policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "CloudwatchLogAccess",
			"Effect": "Allow",
			"Action": [
				"iam:*",
				"secretsmanager:*",
                "ses:*",
                "logs:*",
                "ec2:*"
			],
			"Resource": "*"
		}
	]
}
  EOF
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-security-group"
  description = "Security group for Lambda function"

  vpc_id = var.vpc_id

  # Inbound rule to allow communication within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound rule to allow communication through the NAT gateway
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
