import json
import boto3
import logging
import os
from datetime import datetime
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Environment variables
REGION = os.environ.get('REGION', os.environ.get('AWS_REGION', 'us-east-1'))  # Updated for testing
QUOTA_CODE = os.environ.get('QUOTA_CODE', 'L-0263D0A3')
SERVICE_CODE = os.environ.get('SERVICE_CODE', 'ec2')
USAGE_THRESHOLD = float(os.environ.get('USAGE_THRESHOLD', '50.0'))
QUOTA_INCREMENT = int(os.environ.get('QUOTA_INCREMENT', '1'))
ENABLE_QUOTA_INCREASE = os.environ.get('ENABLE_QUOTA_INCREASE', 'true').lower() == 'true'

# Initialize AWS clients with error handling
def get_aws_client(service_name: str):
    """Get AWS client with proper error handling and retry configuration"""
    try:
        return boto3.client(
            service_name,
            region_name=REGION,
            config=boto3.session.Config(
                retries=dict(
                    max_attempts=3,
                    mode='adaptive'
                )
            )
        )
    except Exception as e:
        logger.error(f"Failed to create {service_name} client: {e}")
        raise

def get_elastic_ip_quota() -> Optional[int]:
    """Get the current Elastic IP service quota for the account"""
    try:
        service_quotas_client = get_aws_client('service-quotas')
        response = service_quotas_client.get_service_quota(
            ServiceCode=SERVICE_CODE,
            QuotaCode=QUOTA_CODE
        )
        quota_value = response['Quota']['Value']
        logger.info(f"Current Elastic IP quota: {quota_value}")
        return quota_value
    except Exception as e:
        logger.error(f"Error getting Elastic IP quota: {e}")
        return None

def get_elastic_ip_count() -> Optional[int]:
    """Get the current count of Elastic IPs in the region"""
    try:
        ec2_client = get_aws_client('ec2')
        response = ec2_client.describe_addresses()
        count = len(response['Addresses'])
        logger.info(f"Current Elastic IP count: {count}")
        return count
    except Exception as e:
        logger.error(f"Error getting Elastic IP count: {e}")
        return None

def create_quota_increase_request(current_quota: int) -> bool:
    """Create a service quota increase request"""
    if not ENABLE_QUOTA_INCREASE:
        logger.info("Quota increase is disabled via environment variable")
        return False
        
    try:
        service_quotas_client = get_aws_client('service-quotas')
        new_quota = current_quota + QUOTA_INCREMENT
        
        response = service_quotas_client.request_service_quota_increase(
            ServiceCode=SERVICE_CODE,
            QuotaCode=QUOTA_CODE,
            DesiredValue=new_quota
        )
        
        request_id = response['RequestedQuota']['RequestId']
        logger.info(f"Quota increase request created successfully. Request ID: {request_id}")
        
        # Send notification to SNS if configured
        sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
        if sns_topic_arn:
            send_sns_notification(sns_topic_arn, request_id, current_quota, new_quota)
        
        return True
        
    except Exception as e:
        logger.error(f"Error creating quota increase request: {e}")
        return False

def send_sns_notification(topic_arn: str, request_id: str, current_quota: int, new_quota: int):
    """Send SNS notification about quota increase request"""
    try:
        sns_client = get_aws_client('sns')
        message = {
            'subject': 'Elastic IP Quota Increase Requested',
            'body': f"""
            Elastic IP quota increase has been requested.
            
            Current Quota: {current_quota}
            Requested Quota: {new_quota}
            Request ID: {request_id}
            Region: {REGION}
            Timestamp: {datetime.utcnow().isoformat()}
            """
        }
        
        sns_client.publish(
            TopicArn=topic_arn,
            Subject=message['subject'],
            Message=message['body']
        )
        logger.info(f"SNS notification sent to {topic_arn}")
        
    except Exception as e:
        logger.error(f"Failed to send SNS notification: {e}")

def validate_event(event: Dict[str, Any]) -> bool:
    """Validate the incoming event structure"""
    try:
        if 'detail' not in event:
            logger.warning("Event missing 'detail' section")
            return False
            
        detail = event['detail']
        required_fields = ['eventName', 'eventSource']
        
        for field in required_fields:
            if field not in detail:
                logger.warning(f"Event detail missing required field: {field}")
                return False
                
        return True
        
    except Exception as e:
        logger.error(f"Error validating event: {e}")
        return False

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Main Lambda function handler"""
    try:
        logger.info(f"Event received: {json.dumps(event)}")
        logger.info(f"Lambda function version: {context.function_version}")
        logger.info(f"Request ID: {context.aws_request_id}")
        
        # Validate event structure
        if not validate_event(event):
            return {
                'statusCode': 400,
                'body': 'Invalid event structure'
            }
        
        event_detail = event['detail']
        event_name = event_detail.get('eventName', '')
        event_source = event_detail.get('eventSource', '')
        
        # Check if this is an Elastic IP allocation event
        if event_name == 'AllocateAddress' and event_source == 'ec2.amazonaws.com':
            logger.info("Elastic IP allocation detected")
            
            # Get current quota and usage
            current_quota = get_elastic_ip_quota()
            current_count = get_elastic_ip_count()
            
            if current_quota is None or current_count is None:
                logger.error("Unable to retrieve quota or count information")
                return {
                    'statusCode': 500,
                    'body': 'Error retrieving quota information'
                }
            
            # Calculate usage percentage
            usage_percentage = (current_count / current_quota) * 100
            logger.info(f"Current usage: {current_count}/{current_quota} ({usage_percentage:.2f}%)")
            
            # Check if usage is at or above threshold
            if usage_percentage >= USAGE_THRESHOLD:
                logger.warning(f"Elastic IP usage is at {usage_percentage:.2f}%. Requesting quota increase.")
                
                # Create quota increase request
                if create_quota_increase_request(current_quota):
                    logger.info("Quota increase request submitted successfully")
                    return {
                        'statusCode': 200,
                        'body': json.dumps({
                            'message': 'Quota increase requested successfully',
                            'current_usage_percentage': round(usage_percentage, 2),
                            'current_quota': current_quota,
                            'requested_quota': current_quota + QUOTA_INCREMENT,
                            'threshold': USAGE_THRESHOLD
                        })
                    }
                else:
                    logger.error("Failed to submit quota increase request")
                    return {
                        'statusCode': 500,
                        'body': 'Failed to submit quota increase request'
                    }
            else:
                logger.info(f"Usage is below {USAGE_THRESHOLD}% threshold. No action needed.")
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Usage is below threshold',
                        'current_usage_percentage': round(usage_percentage, 2),
                        'threshold': USAGE_THRESHOLD
                    })
                }
        else:
            logger.info(f"Event {event_name} from {event_source} is not an Elastic IP allocation")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Event processed but not an Elastic IP allocation',
                    'event_name': event_name,
                    'event_source': event_source
                })
            }
            
    except Exception as e:
        logger.error(f"Unexpected error in lambda_handler: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }
