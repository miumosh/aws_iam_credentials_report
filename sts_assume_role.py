import boto3
from boto3.session import Session


def sts_assume_role(
        account_id: str,          # Switch destination account ID
        role: str,                # Switch destination role name
        region: str,              # Switch destination default region
        operator: str,            # Switch action operator name
        profile: str = 'default', # Non-default profiles can be specified
    ) -> Session:
    
    client = boto3.client('sts')
    
    role_arn = f'arn:aws:iam::{account_id}:role/{role}'
    session_name = f'{operator}'
    
    response = client.assume_role(
        RoleArn = role_arn,
        RoleSessionName = session_name,
    )
    
    session = Session(
        aws_access_key_id = response['Credentials']['AccessKeyId'],
        aws_secret_access_key = response['Credentials']['SecretAccessKey'],
        aws_session_token = response['Credentials']['SessionToken'],
        region_name = region,
        profile_name = profile,
    )
    
    return session
