#!/usr/bin/env python3

import boto3
import datetime
import tarfile
import time


ec2client = boto3.client('ec2')
logsclient = boto3.client('logs')
s3client = boto3.client('s3')


def get_instance_id(server_nametag):
    instances = ec2client.describe_instances(
        Filters = [
            {
                'Name': 'tag:Name',
                'Values': [server_nametag]
            }
        ]
    )
    
    if len(instances['Reservations']) > 0:
        instance_count = len(instances['Reservations'][0]['Instances'])
        if instance_count > 1:
            raise Exception('ERROR: Query returned more than one instance with the specified tag!')
    else:
        raise Exception('ERROR: Query returned zero instances with the specified tag!')
    
    iid = instances['Reservations'][0]['Instances'][0]['InstanceId']
    
    return iid
# end get_instance_id


def get_allocation_id():
    eips = ec2client.describe_addresses(
        Filters = [
            {
                'Name': 'tag:Name',
                'Values': ['bedrock-server-eip']
            }
        ]
    )

    if len(eips['Addresses']) > 0:
        eip_count = len(eips['Addresses'][0])
        if eip_count > 1:
            raise Exception('ERROR: Query returned more than one EIP with the specified tag!')
    else:
        raise Exception('ERROR: Query returned zero EIPs with the specified tag!')
    
    allocation_id = eips['Addresses'][0]['AllocationId']
    
    return allocation_id
# end get_allocation_id


def assign_eip(iid):
    allocation_id = get_allocation_id()

    ec2client.associate_address(
        AllocationId = allocation_id,
        InstanceId = iid
    )
# end assign_eip


def start_worker_instance():
    iid = get_instance_id('bedrock-server-worker')
    
    ec2client.start_instances(InstanceIds = [iid])
    assign_eip(iid)
# end start_worker_instance


def stop_worker_instance():
    worker_iid = get_instance_id('bedrock-server-worker')
    doorknocker_iid = get_instance_id('bedrock-server-doorknocker')
    
    ec2client.stop_instances(InstanceIds = [worker_iid])
    assign_eip(doorknocker_iid)
# end stop_worker_instance


def worker_is_on():
    iid = get_instance_id('bedrock-server-worker')
    instance = ec2client.describe_instances(InstanceIds = [iid])
    instance_state = instance['Reservations'][0]['Instances'][0]['State']

    if instance_state == 'running':
        return True
    else:
        return False
# end worker_is_on


def doorknocker_was_hit():
    response = logsclient.get_log_events(
        logGroupName='/aws/ec2/minecraft-bedrock-server',
        logStreamName='bedrock-server',
        limit=1
    )

    last_logtime_actual = response['events'][0]['timestamp']

    # Read in last seen logtime, and write out the last actual logtime to replace it
    with open('/mnt/efs/last_logtime_known', 'r+') as f:
        try:
            last_logtime_known = int(f.read())
        except FileNotFoundError:
            print('File /mnt/efs/last_logtime_known not found, will create')
            last_logtime_known = 0
        f.write(last_logtime_actual)

    if last_logtime_actual > last_logtime_known:
        return True
    else:
        return False
# end doorknocker_was_hit


def backup_gamedata_to_s3():
    bakfile = '/mnt/efs/bedrock-server-backup.tar.gz'
    account_number = boto3.client('sts').get_caller_identity().get('Account')
    bucket = f'minecraft-bedrock-server-{account_number}'
    minute = datetime.datetime.now().minute
    now = int(time.time())

    # Only backup once per hour at the top of the hour
    if minute != 0:
        return

    # Read in last backup time, and write out the last actual bacup time to replace it
    with open('/mnt/efs/last_backup_time', 'r+') as f:
        try:
            last_backup_time = int(f.read())
        except FileNotFoundError:
            print('File /mnt/efs/last_backup_time not found, will create')
            last_backup_time = 0
        f.write(last_backup_time)
    
    # Make sure backups only run once at the top of the hour, not every function call
    if (now - last_backup_time) > 60:
        with tarfile.open('/mnt/efs/bedrock-server-backup.tar.gz', 'w:gz') as tar:
            tar.add('/mnt/efs/bedrock-server')
        s3client.create_bucket(Bucket = bucket) or print(f'Bucket {bucket} already exists')
        s3client.upload_file(bakfile, bucket)
    else:
        pass
# end backup_gamedata_to_s3
