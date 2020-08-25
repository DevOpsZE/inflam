# Specify the parent image
FROM debian:latest

# Set the working directory
WORKDIR /root/

RUN apt-get update && apt-get upgrade -q -y --force-yes && apt-get install python -y && apt-get install python-pip && pip install boto3

# Copy files from your host to your current working directory
COPY ./terraform-aws-jenkins/files/var/lib/jenkins/script.sh /root/script.sh
COPY ./terraform-aws-jenkins/files/var/lib/jenkins/requirements.txt /root/requirements.txt
COPY ./terraform-aws-jenkins/files/var/lib/jenkins/get-db-instance.py /root/get-db-instance.py

RUN chmod +x /root/script.sh
RUN chmod +x /root/get-db-instance.py

expose 5000

CMD ["sh", "-c" , "./script.sh"]
