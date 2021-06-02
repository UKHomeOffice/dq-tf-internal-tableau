# pylint: disable=broad-except
"""
Copy files from one S3 location to another
"""
import json
import logging
import urllib.parse
import sys
import os
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
from datetime import datetime, timedelta
from dateutil import tz

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
LOG_GROUP_NAME = None
LOG_STREAM_NAME = None

CONFIG = Config(
    retries=dict(
        max_attempts=20
    )
)


def error_handler(lineno, error, fail=True):

    try:
        LOGGER.error('The following error has occurred on line: %s', lineno)
        LOGGER.error(str(error))
        sess = boto3.session.Session()
        region = sess.region_name

        message = "https://{0}.console.aws.amazon.com/cloudwatch/home?region={0}#logEventViewer:group={1};stream={2}".format(region, LOG_GROUP_NAME, LOG_STREAM_NAME)

        send_message_to_slack('OAG Data Ingest Error - Needs immediate attention:: {0}'.format(message))
        if fail:
            sys.exit(1)

    except Exception as err:
        error_handler(sys.exc_info()[2].tb_lineno, err)
        LOGGER.error(
            'The following error has occurred on line: %s',
            sys.exc_info()[2].tb_lineno)
        LOGGER.error(str(err))
        sys.exit(1)


def send_message_to_slack(text):
    """
    Formats the text provides and posts to a specific Slack web app's URL
    Args:
        text : the message to be displayed on the Slack channel
    Returns:
        Slack OAG repsonse
    """

    try:
        post = {
            "text": ":fire: :sad_parrot: *OAG Data Ingest Error - Needs immediate attention:* OAG files are not regularly arriving in *dq-oag-data-ingest Pod* :sad_parrot: :fire:",
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
                    "footer": "AWS OAG",
                    "footer_icon": "https://platform.slack-edge.com/img/default_application_icon.png"
                }
            ]
            }

        ssm_param_name = 'slack_notification_webhook'
        ssm = boto3.client('ssm', config=CONFIG)
        try:
            response = ssm.get_parameter(Name=ssm_param_name, WithDecryption=True)
        except ClientError as e:
            if e.response['Error']['Code'] == 'ParameterNotFound':
                LOGGER.info('Slack SSM parameter %s not found. No notification sent', ssm_param_name)
                return
            else:
                LOGGER.error("Unexpected error when attempting to get Slack webhook URL: %s", e)
                return
        if 'Value' in response['Parameter']:
            url = response['Parameter']['Value']

            json_data = json.dumps(post)
            req = urllib.request.Request(
                url,
                data=json_data.encode('ascii'),
                headers={'Content-Type': 'application/json'})
            LOGGER.info('Sending notification to Slack')
            response = urllib.request.urlopen(req)

        else:
            LOGGER.info('Value for Slack SSM parameter %s not found. No notification sent', ssm_param_name)
            return

    except Exception as err:
        LOGGER.error(
            'The following error has occurred on line: %s',
            sys.exc_info()[2].tb_lineno)
        LOGGER.error(str(err))


# pylint: disable=unused-argument
def lambda_handler(event, context):
    """
    Trigger by cloudwatch rules to check OAG files are reguarly receiving or not
    Args:
        context (LamdaContext) : Runtime information
    Returns:
        null
    """
    try:
        global LOG_GROUP_NAME
        global LOG_STREAM_NAME
        LOG_GROUP_NAME = context.log_group_name
        LOG_STREAM_NAME = context.log_stream_name

        LOGGER.info('The following event was received:')
        LOGGER.info(event)

        bucket_name = os.environ['bucket_name']
        LOGGER.info('bucket_name:{0}'.format(bucket_name))
        threashold_min = os.environ.get('threashold_min', '15')
        LOGGER.info('threashold_min:{0}'.format(threashold_min))

        try:
            from_zone = tz.tzutc()
            #to_zone = tz.gettz('Europe/London')
            threashold_min = int(threashold_min)
            x_mins = datetime.now() - timedelta(minutes=threashold_min)
            x_mins = x_mins.astimezone(from_zone)
            today = datetime.now().astimezone(from_zone)
            prefix_search_previous = x_mins.strftime('%Y-%m-%d') + "/"
            prefix_search_today = today.strftime('%Y-%m-%d') + "/"
            LOGGER.info('built prefix search previous :{0}'.format(prefix_search_previous))
            LOGGER.info('built prefix search today :{0}'.format(prefix_search_today))

            LOGGER.info('Search bucket: {0} and search_paths : {1} and {2}'.format(bucket_name, prefix_search_previous, prefix_search_today))
            s3 = boto3.resource("s3")
            get_last_modified = lambda obj: int(obj.last_modified.strftime('%s'))
            bucket = s3.Bucket(bucket_name)

            # Search objects in the prefix path
            objs_prev = [obj for obj in bucket.objects.filter(Prefix=prefix_search_previous)]
            objs_today = [obj for obj in bucket.objects.filter(Prefix=prefix_search_today)]

            # Get recent from the list
            objs = [obj for obj in sorted(objs_prev + objs_today, key=get_last_modified)]

            if objs:
                obj_name = objs[-1].key.split('/')[-1]
                LOGGER.info('Last file found : {0}'.format(objs[-1].key))
                obj_ts = datetime.strptime(str(objs[-1].last_modified), '%Y-%m-%d %H:%M:%S+00:00')
                obj_utc = obj_ts.replace(tzinfo=from_zone)
                #obj_bst = obj_utc.astimezone(to_zone)
                LOGGER.info('Last file timestamps : {0}'.format(obj_utc.strftime('%Y-%m-%d %H:%M:%S')))
                if x_mins > obj_utc:
                    LOGGER.info('Please investigate dq-oag-data-ingest Kube Pod. We have not received files for last {0} minutes'.format(threashold_min))
                    send_message_to_slack('Please investigate *dq-oag-data-ingest Kube Pod*! Not received files for last {0} minutes. Last file {1} was received on {2} '.format(threashold_min, obj_name, obj_utc))
                else:
                    LOGGER.info('Files have been received within the last {0} minutes, nothing to do'.format(threashold_min))
            else:
                LOGGER.info('No OAG file found for {0}'.format(x_mins.strftime('%Y-%m-%d')))
                send_message_to_slack('Please investigate *dq-oag-data-ingest Kube Pod*! No OAG file found for {0}'.format(x_mins.strftime('%Y-%m-%d')))

        except Exception as err:
            error_handler(sys.exc_info()[2].tb_lineno, err)

        LOGGER.info("We're done here")

    except Exception as err:
        error_handler(sys.exc_info()[2].tb_lineno, err)
