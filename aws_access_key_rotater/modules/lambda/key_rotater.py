import boto3
import os
import json
from datetime import datetime, timedelta, timezone
from botocore.exceptions import ClientError

# Set up environment variables
key_age = os.environ['KEY_AGE']
sender_email = os.environ['ADMIN_EMAIL']
admin_user = os.environ['ADMIN_USERNAME']
account_id = os.environ['AWS_ACCOUNT_ID']
role_arn = os.environ['ROLE_ARN']

def create_access_key(iam, user_name):
    try:
        response = iam.create_access_key(UserName=user_name)
        return response['AccessKey']
    except ClientError as e:
        print(f"Failed to create access key for user {user_name}: {e}")
        return None      


def disable_access_key(iam, user_name, access_key_id):
    try:
        iam.update_access_key(UserName=user_name, AccessKeyId=access_key_id, Status='Inactive')
        iam.tag_user(UserName=user_name, Tags=[{'Key': 'DeleteOn', 'Value': (datetime.now(timezone.utc) + timedelta(days=10)).strftime("%Y-%m-%d")}])
    except ClientError as e:
        print(f"Failed to disable access key {access_key_id} for user {user_name}: {e}")

def delete_access_key(iam, access_key_id):
    try:
        iam.delete_access_key(AccessKeyId=access_key_id)
    except ClientError as e:
        print(f"Failed to delete access key {access_key_id}: {e}")

def secret_store(user_name, access_key, secret_key):
    # Initialize the Secrets Manager client
    secrets_client = boto3.client('secretsmanager')
    secret_values = {
        'username': f'{user_name}',
        'Access_key': f'{access_key}',
        'Secret_key': f'{secret_key}'
    }

    # Convert the dictionary to a JSON string
    secret_value = json.dumps(secret_values)
    
    # Create a new secret
    secret_name = f'{user_name}-credentials-5'

    try:
        secret_response = secrets_client.create_secret(
            Name=secret_name,
            SecretString=secret_value,
            Tags=[
                {
                    'Key': 'CreatedFor',
                    'Value': f'{user_name}'
                },
            ]
        )

        resource_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": f"arn:aws:iam::{account_id}:user/{user_name}"
                    },
                    "Action": "secretsmanager:GetSecretValue",
                    "Resource": f"{secret_response['ARN']}"
                },
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": f"arn:aws:iam::{account_id}:user/{admin_user}"
                    },
                    "Action": "secretsmanager:GetSecretValue",
                    "Resource": f"{secret_response['ARN']}"
                },
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": f"{role_arn}"
                    },
                    "Action": "secretsmanager:Update*",
                    "Resource": f"{secret_response['ARN']}"
                }

            ]
        }
        
        print(resource_policy)

        resource_policy_str = json.dumps(resource_policy)

        # Update the secret resource policy
        secrets_client.put_resource_policy(
            SecretId=secret_response['ARN'],
            ResourcePolicy=resource_policy_str
        )
    except:
        try:
            print("Secret already exist, updating secret value")
            secret_response = secrets_client.update_secret(
                SecretId=secret_name,
                SecretString=secret_value
            )
        except ClientError as e:
            print(f"Failed to create and update secret for the user {user_name}: {e}")

def notify_user(user_name, message):
    # Define the email subject and body
    subject = "Access Key Notification"
    body = f"Dear {user_name},\n\n{message}\n\nRegards,\nAdmin"

    # Specify the sender and recipient email addresses
    sender = sender_email
    recipient = user_name

    # Create a client for AWS Simple Email Service (SES)
    ses = boto3.client('ses')

    # Send the email
    try:
        response = ses.send_email(
            Source=sender,
            Destination={'ToAddresses': [recipient]},
            Message={'Subject': {'Charset': 'UTF-8', 'Data': subject}, 'Body': {'Text': {'Charset': 'UTF-8', 'Data': body}}}
        )
        print(f"Email notification sent to user {user_name}")
    except Exception as e:
        print(f"Failed to send email notification to user {user_name}: {e}")


def process_user(iam, user):
    user_name = user['UserName']
    access_keys = iam.list_access_keys(UserName=user_name)['AccessKeyMetadata']
    num_keys = len(access_keys)

    # Get the current date and time with timezone information
    now = datetime.now(timezone.utc)

    # Set the number of days for access key expiration
    n_days = int(key_age)

    # Calculate the date 'n_days' ago
    cutoff_date = now - timedelta(days=n_days)

    # Check if user has any access keys
    if num_keys > 0:
        expired_keys = [key for key in access_keys if key['CreateDate'].replace(tzinfo=timezone.utc) < cutoff_date]
        active_keys = [key for key in access_keys if key['Status'] == 'Active']
        disabled_keys = [key for key in access_keys if key['Status'] == 'Inactive']

        # Case 1: User has 2 access keys
        if num_keys == 2:
            if len(active_keys) == 2:
                notify_user(user_name, "User already has two active keys. Moving to the next user")
                return

            # Delete disabled keys
            for key in disabled_keys:
                tags_response = iam.list_user_tags(UserName=user_name)
                tags = tags_response['Tags']
                # Check if the user has the 'DeleteOn' tag
                for tag in tags:
                    if tag['Key'] == 'DeleteOn':
                        # Store the value of the 'DeleteOn' tag in 'delete_date'
                        delete_date = tag['Value']
                        # Perform your desired action using 'delete_date'
                        print(f"User {user_name} has the 'DeleteOn' tag with value: {delete_date}.")
                    else:
                        delete_date = None
                try:
                    delete_date = datetime.strptime(key['Tags'][0]['Value'], "%Y-%m-%d")
                except (KeyError, ValueError):
                    delete_date = now + timedelta(days=30)

                if delete_date <= now:
                    delete_access_key(iam, key['AccessKeyId'])
                else:
                    notify_user(user_name, f"The access key {key['AccessKeyId']} is already disabled. This key will be deleted after {delete_date.strftime('%Y-%m-%d')}.")

            if expired_keys:
                new_key = create_access_key(iam, user_name)
                if new_key:
                    disable_access_key(iam, user_name, expired_keys[0]['AccessKeyId'])
                    secret_store(user_name, new_key['AccessKeyId'], new_key['SecretAccessKey'])
                    notify_user(user_name, f"Your access key has been rotated. \n Please find the information below:\n Access Key: {new_key['AccessKeyId']} \n Secret Access Key: {new_key['SecretAccessKey']}.\n Please update your credentials.")
            else:
                notify_user(user_name, "User has two active keys, and none are expired. Moving to the next user")

        # Case 2: User has 1 access key
        elif num_keys == 1:
            key = access_keys[0]

            if key['Status'] == 'Inactive':
            # Delete disabled keys
                for key in disabled_keys:
                    tags_response = iam.list_user_tags(UserName=user_name)
                    tags = tags_response['Tags']
                    # Check if the user has the 'DeleteOn' tag
                    for tag in tags:
                        if tag['Key'] == 'DeleteOn':
                            # Store the value of the 'DeleteOn' tag in 'delete_date'
                            delete_date = tag['Value']
                            # Perform your desired action using 'delete_date'
                            print(f"User {user_name} has the 'DeleteOn' tag with value: {delete_date}.")
                        else:
                            delete_date = None
                    try:
                        delete_date = datetime.strptime(key['Tags'][0]['Value'], "%Y-%m-%d")
                    except (KeyError, ValueError):
                        delete_date = now + timedelta(days=30)

                    if delete_date <= now:
                        delete_access_key(iam, key['AccessKeyId'])
                    else:
                        notify_user(user_name, f"The access key {key['AccessKeyId']} is already disabled. This key will be deleted after {delete_date.strftime('%Y-%m-%d')}.")
                        iam.tag_user(UserName=user_name, Tags=[{'Key': 'DeleteOn', 'Value': (datetime.now(timezone.utc) + timedelta(days=10)).strftime("%Y-%m-%d")}])
                notify_user(user_name, f"Access key {key['AccessKeyId']} is already in a disabled state.")
            else:
                if expired_keys:
                    disable_access_key(iam, user_name, key['AccessKeyId'])
                    new_key = create_access_key(iam, user_name)
                    if new_key:
                        disable_access_key(iam, user_name, expired_keys[0]['AccessKeyId'])
                        secret_store(user_name, new_key['AccessKeyId'], new_key['SecretAccessKey'])
                        notify_user(user_name, f"Your access key has been rotated. \n Please find the information below:\n Access Key: {new_key['AccessKeyId']} \n Secret Access Key: {new_key['SecretAccessKey']}.\n Please update your credentials.")
                else:
                    notify_user(user_name, "User has only one active key, and it is not expired. Moving to the next user")

        # Case 3: User has 0 access keys
        else:
            print("User has no access key created. Skipping the user.")

def lambda_handler(event, context):
    # Create a client for AWS Identity and Access Management (IAM)
    iam = boto3.client('iam')

    # Fetch the list of IAM users
    response = iam.list_users()

    # Process each user
    for user in response['Users']:
        process_user(iam, user)

    # Return success status (optional)
    return {
        'statusCode': 200,
        'body': 'Access keys checked and updated successfully.'
    }
