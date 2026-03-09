import json
import os
import urllib.request

slack_webhook_url = os.environ.get("slackHookUrl")

def lambda_handler(event, context):

    message = json.loads(event['Records'][0]['Sns']['Message'])

    alarm_name = message['AlarmName']
    new_state = message['NewStateValue']
    reason = message['NewStateReason']

    slack_message = {
        'text': "%s state is now %s: %s" % (alarm_name, new_state, reason)
    }

    req = urllib.request.Request(
        slack_webhook_url,
        data=json.dumps(slack_message).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )

    try:
        with urllib.request.urlopen(req) as response:
            response_body = response.read().decode()
            print("Message posted to Slack:", response_body)
    except Exception as e:
        print("Failed to send message:", str(e))
