#!/usr/bin/env python
import boto3

rds = boto3.client('rds')
dbs = rds.describe_db_instances()


def get_tags_for_db(db):
    instance_arn = db['DBInstanceArn']
    instance_tags = rds.list_tags_for_resource(ResourceName=instance_arn)
    return instance_tags['TagList']


target_db = None

for db in dbs['DBInstances']:
    print ("%s@%s:%s %s") % (
        db['MasterUsername'],
        db['Endpoint']['Address'],
        db['Endpoint']['Port'],
        db['DBInstanceStatus'])

    db_tags = get_tags_for_db(db)
    tag = next(iter(filter(lambda tag: tag['Key'] == 'Name' and tag['Value'] == 'APP1', db_tags)), None)
    if tag:
        target_db = db
        break

print(target_db)
