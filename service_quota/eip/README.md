# 🚀 AWS Elastic IP Monitoring Solution

A production-grade, serverless solution for automated monitoring and quota management of AWS Elastic IPs using AWS Lambda, CloudTrail, and EventBridge.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration](#configuration)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [Security](#security)
- [Cost Optimization](#cost-optimization)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This solution automatically monitors Elastic IP allocations in real-time and proactively manages service quotas. When an Elastic IP is allocated, the system:

1. **Detects** the allocation via CloudTrail
2. **Triggers** a Lambda function via EventBridge
3. **Checks** current usage against quotas
4. **Requests** quota increases when thresholds are met
5. **Logs** all activities for audit and monitoring

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   EC2 API   │───▶│ CloudTrail  │───▶│ EventBridge │───▶│   Lambda    │
│ AllocateEIP │    │   Logging   │    │   Rule      │    │  Function   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                           │                   │              │
                           ▼                   ▼              ▼
                    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
                    │   S3 Bucket │    │ CloudWatch  │    │Service Quotas│
                    │   Logs      │    │   Dashboard │    │   API       │
                    └─────────────┘    └─────────────┘    └─────────────┘
```

### Key Components

- **CloudTrail**: Captures all AWS API calls
- **EventBridge**: Routes events to Lambda
- **Lambda Function**: Core monitoring logic
- **S3 Bucket**: Secure log storage
- **CloudWatch**: Monitoring and alerting
- **IAM**: Secure access control

## ✨ Features

- 🔍 **Real-time Monitoring**: Instant detection of Elastic IP allocations
- 📊 **Automated Quota Management**: Proactive quota increase requests
- 🛡️ **Production-Grade Security**: IAM least-privilege access
- 📈 **Scalable Architecture**: Serverless design with auto-scaling
- 🏷️ **Resource Tagging**: Comprehensive tagging for cost management
- 📝 **Audit Trail**: Complete logging and monitoring
- 🔧 **Infrastructure as Code**: Terraform-based deployment
- 📦 **Lambda Layers**: Efficient dependency management

## 📋 Prerequisites

### Required Tools

1. **AWS CLI** (v2.x)
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Verify installation
   aws --version
   ```

2. **Terraform** (v1.0+)
   ```bash
   # Install Terraform
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   sudo apt-get update && sudo apt-get install terraform
   
   # Verify installation
   terraform --version
   ```

3. **Python** (3.9+)
   ```bash
   # Install Python
   sudo apt-get update
   sudo apt-get install python3 python3-pip
   
   # Verify installation
   python3 --version
   pip3 --version
   ```

4. **jq** (JSON processor)
   ```bash
   # Install jq
   sudo apt-get install jq
   
   # Verify installation
   jq --version
   ```

### AWS Account Requirements

- **AWS Account** with appropriate permissions
- **IAM User/Role** with the following permissions:
  - `CloudTrailFullAccess`
  - `LambdaFullAccess`
  - `S3FullAccess`
  - `EventBridgeFullAccess`
  - `CloudWatchFullAccess`
  - `IAMFullAccess`
  - `ServiceQuotasFullAccess`

### AWS CLI Configuration

```bash
# Configure AWS CLI
aws configure

# Enter your credentials:
# AWS Access Key ID: [YOUR_ACCESS_KEY]
# AWS Secret Access Key: [YOUR_SECRET_KEY]
# Default region name: [YOUR_REGION] (e.g., us-east-1)
# Default output format: json
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aws-elastic-ip-monitor
```

### 2. Deploy the Solution

```bash
# Run the automated deployment script
./deploy.sh
```

### 3. Test the Solution

```bash
# Allocate an Elastic IP to trigger the monitoring
aws ec2 allocate-address --region <your-region>
```

## 📖 Step-by-Step Deployment

### Step 1: Environment Setup

1. **Navigate to the project directory**
   ```bash
   cd aws-elastic-ip-monitor
   ```

2. **Verify prerequisites**
   ```bash
   # Check AWS CLI
   aws sts get-caller-identity
   
   # Check Terraform
   terraform --version
   
   # Check Python
   python3 --version
   ```

3. **Set your AWS region**
   ```bash
   export AWS_DEFAULT_REGION=us-east-1
   # or your preferred region
   ```

### Step 2: Configuration

1. **Review the configuration file**
   ```bash
   cat terraform/config.json
   ```

2. **Customize settings** (optional)
   ```json
   {
     "aws_region": "us-east-1",
     "environment": "production",
     "project_name": "elastic-ip-monitor",
     "lambda": {
       "memory_size": 256,
       "timeout": 300,
       "usage_threshold": 50,
       "quota_increment": 1
     }
   }
   ```

### Step 3: Build Lambda Layer

1. **Build the Lambda layer**
   ```bash
   cd lambda-layer
   ./build_layer.sh
   cd ..
   ```

2. **Verify the layer was created**
   ```bash
   ls -la lambda-layer/
   # Should see: elastic-ip-monitor-layer.zip
   ```

### Step 4: Deploy Infrastructure

1. **Navigate to Terraform directory**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Plan the deployment**
   ```bash
   terraform plan
   ```

4. **Apply the configuration**
   ```bash
   terraform apply -auto-approve
   ```

5. **Verify deployment**
   ```bash
   terraform output
   ```

### Step 5: Test the Solution

1. **Test Lambda function directly**
   ```bash
   aws lambda invoke \
     --function-name elastic-ip-monitor-elastic-ip-monitor \
     --cli-binary-format raw-in-base64-out \
     --payload '{"detail":{"eventName":"AllocateAddress","eventSource":"ec2.amazonaws.com"}}' \
     response.json
   
   cat response.json
   ```

2. **Test with real Elastic IP allocation**
   ```bash
   aws ec2 allocate-address --region <your-region>
   ```

3. **Check CloudWatch logs**
   ```bash
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/elastic-ip-monitor-elastic-ip-monitor" \
     --region <your-region> \
     --start-time $(($(date +%s) - 300))000
   ```

## ⚙️ Configuration

### Environment Variables

The Lambda function uses the following environment variables:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `LOG_LEVEL` | Logging level | `INFO` | No |
| `REGION` | AWS region | `us-east-1` | No |
| `QUOTA_CODE` | Service quota code | `L-0263D0A3` | No |
| `SERVICE_CODE` | AWS service code | `ec2` | No |
| `USAGE_THRESHOLD` | Usage threshold % | `50` | No |
| `QUOTA_INCREMENT` | Quota increase amount | `1` | No |
| `ENABLE_QUOTA_INCREASE` | Enable quota increases | `true` | No |
| `SNS_TOPIC_ARN` | SNS topic for alerts | `null` | No |

### Customizing Thresholds

To modify the usage threshold:

1. **Update config.json**
   ```json
   {
     "lambda": {
       "usage_threshold": 75
     }
   }
   ```

2. **Redeploy**
   ```bash
   cd terraform
   terraform apply -auto-approve
   ```

### Adding SNS Notifications

1. **Create SNS topic**
   ```bash
   aws sns create-topic --name elastic-ip-monitor-alerts
   ```

2. **Update config.json**
   ```json
   {
     "lambda": {
       "sns_topic_arn": "arn:aws:sns:region:account:elastic-ip-monitor-alerts"
     }
   }
   ```

3. **Redeploy**
   ```bash
   terraform apply -auto-approve
   ```

## 🧪 Testing

### Manual Testing

1. **Test Lambda function**
   ```bash
   aws lambda invoke \
     --function-name elastic-ip-monitor-elastic-ip-monitor \
     --payload '{"detail":{"eventName":"AllocateAddress","eventSource":"ec2.amazonaws.com"}}' \
     response.json
   ```

2. **Test with real events**
   ```bash
   # Allocate Elastic IP
   aws ec2 allocate-address --region <your-region>
   
   # Check logs
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/elastic-ip-monitor-elastic-ip-monitor" \
     --region <your-region>
   ```

### Automated Testing

1. **Create test payloads**
   ```bash
   echo '{"detail":{"eventName":"AllocateAddress","eventSource":"ec2.amazonaws.com"}}' > test-payload.json
   ```

2. **Run tests**
   ```bash
   # Test allocation event
   aws lambda invoke \
     --function-name elastic-ip-monitor-elastic-ip-monitor \
     --payload file://test-payload.json \
     response.json
   ```

## 📊 Monitoring

### CloudWatch Dashboard

1. **Access the dashboard**
   - Go to AWS Console → CloudWatch → Dashboards
   - Find: `elastic-ip-monitor-elastic-ip-monitoring`

2. **Dashboard components**
   - Lambda function metrics
   - CloudTrail event counts
   - Elastic IP usage trends
   - Error rates and performance

### CloudWatch Logs

1. **View Lambda logs**
   ```bash
   aws logs describe-log-groups \
     --log-group-name-prefix "/aws/lambda/elastic-ip-monitor"
   ```

2. **Filter recent events**
   ```bash
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/elastic-ip-monitor-elastic-ip-monitor" \
     --start-time $(($(date +%s) - 3600))000
   ```

### Metrics to Monitor

- **Lambda Function**
  - Invocation count
  - Duration
  - Error rate
  - Throttles

- **CloudTrail**
  - Event count
  - API call success rate

- **S3**
  - Bucket size
  - Object count
  - Access patterns

## 🔧 Troubleshooting

### Common Issues

#### 1. Lambda Function Errors

**Problem**: `AccessDeniedException` for Service Quotas
```bash
# Check IAM policy
aws iam get-role-policy \
  --role-name elastic-ip-monitor-lambda-execution-role \
  --policy-name elastic-ip-monitor-lambda-custom-policy
```

**Solution**: Ensure the IAM policy includes `service-quotas:*` permissions

#### 2. EventBridge Not Triggering

**Problem**: Lambda function not invoked
```bash
# Check EventBridge rule
aws events describe-rule \
  --name elastic-ip-monitor-elastic-ip-allocation-rule
```

**Solution**: Verify the rule pattern matches CloudTrail events

#### 3. CloudTrail Not Logging

**Problem**: No events in S3 bucket
```bash
# Check CloudTrail status
aws cloudtrail describe-trails \
  --trail-name-list elastic-ip-monitor-elastic-ip-trail
```

**Solution**: Ensure CloudTrail is enabled and logging to S3

### Debug Commands

1. **Check Lambda function status**
   ```bash
   aws lambda get-function \
     --function-name elastic-ip-monitor-elastic-ip-monitor
   ```

2. **Verify IAM role**
   ```bash
   aws iam get-role \
     --role-name elastic-ip-monitor-lambda-execution-role
   ```

3. **Check S3 bucket contents**
   ```bash
   aws s3 ls s3://elastic-ip-monitor-cloudtrail-<suffix>/
   ```

4. **Test EventBridge rule**
   ```bash
   aws events test-event-pattern \
     --event-pattern '{"source":["aws.cloudtrail"],"detail-type":["AWS API Call via CloudTrail"]}' \
     --event '{"source":"aws.cloudtrail","detail-type":"AWS API Call via CloudTrail"}'
   ```

### Log Analysis

1. **View recent errors**
   ```bash
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/elastic-ip-monitor-elastic-ip-monitor" \
     --filter-pattern "ERROR"
   ```

2. **Check specific request ID**
   ```bash
   aws logs filter-log-events \
     --log-group-name "/aws/lambda/elastic-ip-monitor-elastic-ip-monitor" \
     --filter-pattern "RequestId: <request-id>"
   ```

## 🛠️ Maintenance

### Regular Tasks

1. **Monitor CloudWatch metrics** (weekly)
2. **Review CloudTrail logs** (monthly)
3. **Update Lambda dependencies** (quarterly)
4. **Review IAM permissions** (quarterly)
5. **Check S3 lifecycle policies** (monthly)

### Updating the Solution

1. **Update Lambda function**
   ```bash
   # Modify lambda_function.py
   zip -r lambda_function.zip lambda_function.py
   
   # Update via AWS CLI
   aws lambda update-function-code \
     --function-name elastic-ip-monitor-elastic-ip-monitor \
     --zip-file fileb://lambda_function.zip
   ```

2. **Update infrastructure**
   ```bash
   cd terraform
   terraform plan
   terraform apply -auto-approve
   ```

### Backup and Recovery

1. **Backup configuration**
   ```bash
   cp terraform/config.json config.json.backup
   cp terraform/terraform.tfstate terraform.tfstate.backup
   ```

2. **Recovery process**
   ```bash
   # Restore configuration
   cp config.json.backup terraform/config.json
   
   # Redeploy
   cd terraform
   terraform apply -auto-approve
   ```

## 🔒 Security

### Security Features

- **IAM Least Privilege**: Minimal required permissions
- **Encryption at Rest**: S3 SSE-S3 encryption
- **Encryption in Transit**: TLS 1.2+ for all communications
- **Resource Tagging**: Comprehensive security tagging
- **Audit Logging**: Complete CloudTrail logging

### Security Best Practices

1. **Regular IAM reviews**
2. **Monitor CloudTrail for suspicious activity**
3. **Use AWS Config for compliance monitoring**
4. **Enable CloudWatch alarms for security events**
5. **Regular security updates and patches**

### Compliance

- **SOC 2**: Infrastructure logging and monitoring
- **PCI DSS**: Secure data handling and access control
- **HIPAA**: Audit trails and access logging
- **ISO 27001**: Information security management

## 💰 Cost Optimization

### Cost Breakdown

- **Lambda**: ~$0.20 per million requests
- **CloudTrail**: First 90 days free, then $0.50 per 100,000 events
- **S3**: ~$0.023 per GB-month
- **CloudWatch**: Basic monitoring included
- **EventBridge**: $1.00 per million events

### Optimization Strategies

1. **S3 Lifecycle Policies**: Move old logs to cheaper storage
2. **CloudTrail Event Selectors**: Log only necessary events
3. **Lambda Memory**: Optimize memory allocation
4. **Log Retention**: Set appropriate retention periods

### Cost Monitoring

1. **Set up billing alerts**
2. **Use Cost Explorer for analysis**
3. **Monitor resource usage**
4. **Review and optimize regularly**

## 🤝 Contributing

### Development Setup

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Test thoroughly**
5. **Submit a pull request**

### Development Guidelines

- Follow AWS best practices
- Include comprehensive testing
- Update documentation
- Follow the existing code style
- Add appropriate error handling

### Testing Requirements

- Unit tests for Lambda functions
- Integration tests for AWS services
- Terraform validation
- Security scanning

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### Getting Help

1. **Check the troubleshooting section**
2. **Review CloudWatch logs**
3. **Check AWS Service Health Dashboard**
4. **Open an issue on GitHub**

### Useful Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS CloudTrail Documentation](https://docs.aws.amazon.com/cloudtrail/)
- [AWS EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws)

### Community

- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share solutions
- **Wiki**: Additional documentation and examples

---

**Note**: This solution is designed for production use but should be thoroughly tested in your environment before deployment. Always follow your organization's security and compliance requirements.
