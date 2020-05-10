#!/usr/bin/env python3

import boto3
import datetime
import time

client = boto3.client('logs')

response = client.get_log_events(
    logGroupName = '/aws/ec2/minecraft-bedrock-server',
    logStreamName = 'bedrock-server',
    limit = 1
)

last_logtime_actual = response['events'][0]['timestamp']

# Read in last seen logtime, and write out the last actual logtime to replace it
with open('/mnt/efs/last_logtime_known', 'r+') as f:
  last_logtime_known = int(f.read())
  f.write(last_logtime_actual)

if last_logtime_actual > last_logtime_known:
  try:
    start_worker_instance()
  except SomeException as e:
    print(e)
else:
  if worker_is_on():
    try:
      stop_worker_instance()
    except ClientException as e:
      print(e)

print(last_logtime_actual)

time.sleep(5)
