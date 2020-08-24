 #!/bin/sh
echo "REPOSITORY: terraform-aws-jenkins"
echo "SCRIPT: upload_static_website_to_s3.sh <s3prefix> <region>"
echo "EXECUTING: upload_static_website_to_s3.sh"

s3_prefix=$1
if [ -z "$s3_prefix" ]; then
    echo "An s3prefix must be provided! Failing out."
fi

target_aws_region=$2
if [ -z "$target_aws_region" ]; then
    target_aws_region=us-east-1
    echo "No region was passed in, using \"${target_aws_region}\" as the default"
fi

# This script uploads the website files to S3 bucket
echo "Uploading Static Website Files to S3 

aws s3 cp --recursive ./terraform-aws-jenkins/s3-static-website-files/ s3://${s3_prefix}-s3-static-website-${target_aws_region}/


echo "# # # # # # # # DONE # # # # # # # # # #" 
