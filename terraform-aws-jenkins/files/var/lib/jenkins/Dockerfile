# Specify the parent image
FROM python:2

# Set the working directory
WORKDIR /root/

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy files from your host to your current working directory
COPY ./terraform-aws-jenkins/files/var/lib/jenkins/script.sh /root/script.sh
COPY ./terraform-aws-jenkins/files/var/lib/jenkins/get-db-instance.py /root/get-db-instance.py

RUN chmod +x /root/script.sh
RUN chmod +x /root/get-db-instance.py

expose 5000

CMD ["sh", "-c" , "./script.sh"]
