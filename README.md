# inflam
DevOps Task
-------------
Requirements:
+Git
+Terraform
+Jenkins
+Docker
+Python
+Python-pip
-------------

1. Start initial prep script (run prerequisites).
  go to: terraform-aws-init 

2. ./tf-plan.sh <s3_prefix> <region> <public_key_path>   example--> ~/.ssh/authorized_keys

3. ./tf-apply.sh <s3_prefix> <region> <public_key_path>  example--> ~/.ssh/authorized_keys

  **to destroy: ./tf-destroy.sh <s3prefix> <region>**

4. Create Resources with Terraform:
 
  go to: terraform-aws-jenkins

  ./tf-plan.sh <s3_prefix> <region>
  ./tf-apply.sh <s3_prefix> <region> 

  **to destroy: ./tf-destroy.sh <s3prefix> <region>**

 !!! Don`t forget save the outputs as they will be needed later !!!

5. SSH into the Jenkins EC2 and switch to the Jenkins user (use the output information). Move to the Jenkins home directory.

  sudo su jenkins && cd ~/

  or navigate to:
  cd ~   -->> /var/lib/jenkins

6. Run the git config script:
 ./configure-git.sh

7. Copy/Paste your key into GitHub Acc and Save

8. Access Jenkins server using the information from the Terraform outputs.
!!! Don`t forget save the outputs as they will be needed later !!!

9. Setup ssh key for Jenkins on the Freestyle/Pipeline project building step:

 cd .ssh

 cat id_rsa ---> copy the key and insert it in Jenkins (this is for adding a key for source control)

Add Credentials --> Kind (SSH Username with private key) -->>> Type a username and paste the private   key

10. Check and remove (if present) .aws folder in user: Jenkins (helps to avoid invalid security token pro9blems)
 command: rm -r .aws

12. Set up aws credentials:
 $ aws configure
 AWS Access Key ID [None]: <your access key>
 AWS Secret Access Key [None]: <your secret key>
 Default region name [None]: <your region name>
 Default output format [None]: ENTER

13. Go back to Jenkins GUI and complete the project by adding the source, build and deploy steps.

14. Initiate the Build process.

15. Check the console output.
