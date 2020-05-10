#!/usr/bin/env python3

import boto3
import datetime
import time

def start_worker_instance():
    pass
# end start_worker_instance


def stop_worker_instance():
    pass
# end stop_worker_instance


def worker_is_on():
    pass
# end worker_is_on


def logs_say_do_something():
    client = boto3.client('logs')

    try:
        response = client.get_log_events(
            logGroupName='/aws/ec2/minecraft-bedrock-server',
            logStreamName='bedrock-server',
            limit=1
        )
    except ClientException as e:
        print(e)

    last_logtime_actual = response['events'][0]['timestamp']

    # Read in last seen logtime, and write out the last actual logtime to replace it
    with open('/mnt/efs/last_logtime_known', 'r+') as f:
        last_logtime_known = int(f.read())
        f.write(last_logtime_actual)

    if last_logtime_actual > last_logtime_known:
        return True
    else:
        return False
# end logs_say_do_something


def main():
    if logs_say_do_something():
        start_worker_instance()
    else:
        if worker_is_on():
            stop_worker_instance()
    time.sleep(5)
# end main

if __name__ == '__main__':
    main()
