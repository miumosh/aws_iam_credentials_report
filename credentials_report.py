import boto3
import logging
import time
from botocore.exceptions import ClientError


logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)


def generate_credential_report(session):
    try:
        client = session.client('iam')
        response = client.generate_credential_report()
    except ClientError:
        logger.exception('ERROR: generate credentials report.')
        raise
    else:
        return response


def get_credential_report(session):
    try:
        client = session.client('iam')
        response = client.get_credential_report()
    except ClientError:
        logger.exception('ERROR: get credentials report.')
        raise
    else:
        return response['Content']



def credential_report(session):
    response = generate_credential_report(session)
    
    if response['State'] != 'COMPLETE':
        time.sleep(10)

    report = get_credential_report(session)
    return report
