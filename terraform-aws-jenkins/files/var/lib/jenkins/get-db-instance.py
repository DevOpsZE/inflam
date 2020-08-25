#!/usr/bin/env python
import boto3
rds = boto3.client('rds', region_name='us-east-1')
try:
# get all db instances
    dbs = rds.describe_db_instances()
    for db in dbs['DBInstances']:
        print ("%s@%s:%s %s") % (
            db['MasterUsername'],
            db['Endpoint']['Address'],
            db['Endpoint']['Port'],
            db['DBInstanceStatus'])
except Exception as error:
    print error

# Retrieve Database Credentials from SSM Parameter Store
ssm = boto3.client('ssm', region_name='us-east-1')
parameter = ssm.get_parameter(Name='/test/database/postgresql/zlatin/username',WithDecryption=True)
print(parameter['Parameter']['Value'])

ssm = boto3.client('ssm', region_name='us-east-1')
parameter = ssm.get_parameter(Name='/test/database/postgresql/zlatin/password',
WithDecryption=True)
print(parameter['Parameter']['Value'])
