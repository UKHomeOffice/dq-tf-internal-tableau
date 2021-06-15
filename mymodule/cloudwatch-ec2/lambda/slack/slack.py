"""
Receives a message from SNS and send a notification to Slack
"""

import json
import logging
import sys
import urllib.parse
import urllib.request
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

CONFIG = Config(
    retries=dict(
        max_attempts=20
    )
)


def lambda_handler(event, context):
    """
    Formats the JSON received by SNS and calls the send_message_to_slack() function
    """
    LOGGER.info("Received SNS Event: " + "\n" + "%s", event)
    message = event['Records'][0]['Sns']['Message']
    json_message = json.loads(message)
    alarm_check = json_message.get('NewStateValue')
    alarm_name = json_message.get('AlarmName')
    alarm_desc = json_message.get('AlarmDescription')
    text = "*Instance:* " + alarm_name + '\n' + "*Description:* " + alarm_desc

    if alarm_check == 'ALARM':
        send_message_to_slack(text)
    else:
        pass


def send_message_to_slack(text):
    """
    Formats the text and posts to a specific Slack web app's URL
    """
    try:
        post = {
            "text": ":fire: :sad_parrot: An *EC2* alarm has occured :sad_parrot: :fire:",
            "attachments": [
                {
                    "text": "{0}".format(text),
                    "color": "#B22222",
                    "attachment_type": "default",
                    "fields": [
                        {
                            "title": "Priority",
                            "value": "High",
                            "short": "false"
                        }
                    ],
                    "footer": "Cloudwatch Alarms",
                    "footer_icon": "https://platform.slack-edge.com/img/default_application_icon.png"
                }
            ]
            }

        ssm_param_name = 'slack_notification_webhook'
        ssm = boto3.client('ssm', config=CONFIG)

        try:
            response = ssm.get_parameter(Name=ssm_param_name, WithDecryption=True)
        except ClientError as err:
            if err.response['Error']['Code'] == 'ParameterNotFound':
                LOGGER.info("Slack SSM parameter %s not found. No notification sent", ssm_param_name)
                return
            else:
                LOGGER.error("Unexpected error when attempting to get Slack webhook URL: %s", err)
                return

        if 'Value' in response['Parameter']:
            url = response['Parameter']['Value']
            json_data = json.dumps(post)
            req = urllib.request.Request(
                url,
                data=json_data.encode('utf-8'),
                headers={'Content-Type': 'application/json'})
            LOGGER.info("Sending notification to Slack")
            response = urllib.request.urlopen(req)
            LOGGER.info("HTTP status code received from Slack API: %s", response.getcode())
        else:
            LOGGER.info("Value for Slack SSM parameter %s not found. No notification sent", ssm_param_name)
            return

    except Exception as err:
        LOGGER.error(
            "The following error has occurred on line: %s",
            sys.exc_info()[2].tb_lineno)
        LOGGER.error(str(err))
