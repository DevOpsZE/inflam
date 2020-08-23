#!/usr/bin/env bash

# Non-interactive shell
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

## Set Timezone to UTC
timedatectl set-timezone UTC

## Install Misc Deps
echo "Installing misc binaries"
apt-get update
apt-get install -y git wget jq vim unzip ca-certificates

## Install Docker-CE
echo "Installing Docker"
groupadd docker
apt-get install -y apt-transport-https curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

# Install PHP 7.1 via sury mirror - https://twitter.com/debsuryorg
echo "Installing PHP 7.1"
apt-get install -y apt-transport-https lsb-release
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
apt-get update
apt-get install -y php7.1 php7.1-xml php7.1-mbstring php7.1-curl

## GetComposer.org
echo "Installing Composer"
/usr/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
# When an update to composer happens, you need to update this hash. https://getcomposer.org/download/
/usr/bin/php -r "if (hash_file('sha384', 'composer-setup.php') === '572cb359b56ad9ae52f9c23d29d4b19a040af10d6635642e646a7caa7b96de717ce683bd797a92ce99e5929cc51e7d5f') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
/usr/bin/php composer-setup.php
/usr/bin/php -r "unlink('composer-setup.php');"
chmod +x composer.phar
mv composer.phar /usr/local/bin/composer

#####
## Install Java + Jenkins + Plugins
#####

## Install Oracle Java 8
echo "Installing Oracle Java 8"
#echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
#echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | sudo tee /etc/apt/sources.list.d/oraclejava8.list
#echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | sudo tee -a /etc/apt/sources.list.d/oraclejava8.list
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
apt-get update
apt-get install -y openjdk-11-jre openjdk-11-jdk
# Make sure Java 8 becomes default java
#apt-get install -y oracle-java8-set-default

## Install Jenkins
echo "Installing Jenkins"
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
# Add jenkins debian repo to sources file if it doesn't exist
if ! grep -q "deb https://pkg.jenkins.io/debian binary/" /etc/apt/sources.list; then
    echo "deb https://pkg.jenkins.io/debian binary/" | sudo tee -a /etc/apt/sources.list
fi
apt-get update
apt-get install -y jenkins

# Replace Config to skip Jenkins Setup
echo "Removing Jenkins Security"
sed -i -e 's#^JAVA_ARGS="-Djava.awt.headless=true"#JAVA_ARGS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"#' /etc/default/jenkins
# Delete config file so a new one is generated without security enabled
if grep -q "<authorizationStrategy class=\"hudson.security.FullControlOnceLoggedInAuthorizationStrategy\">" /var/lib/jenkins/config.xml; then
    rm /var/lib/jenkins/config.xml
fi

echo "Setting up Jenkins"
# Chown it over to the jenkins user
chown -h jenkins:root /var/lib/jenkins

# Download Jenkins Jar so that we can run commands from the CLI to Jenkins
printf '%s\n' 'Waiting for Jenkins to restart'
service jenkins restart  || {
    printf '%s\n' 'Failed to Start Jenkins'
    exit 1
}

# Set Jenkins to autostart on reboot
printf  '%s\n' 'Adding Jenkins to update-rc.d'
update-rc.d jenkins defaults || {
    printf '%s\n' 'Failed to add Jenkins to update-rc.d'
    exit 1
}

# Fetch the Jenkins CLI jar
until wget -O /root/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar; do
    echo "Trying to download jenkins-cli.jar attempt."
    sleep 10
done

# Test Jar installation
printf '%s\n' 'Testing Jenkins Installation'
java -jar /root/jenkins-cli.jar -s http://localhost:8080/ help || {
    printf '%s\n' 'Running jar for jenkins failed'
    exit 1
}

# Update jenkins plugins
printf '%s\n' 'Updating Jenkins Plugins'
UPDATE_LIST=$( java -jar /root/jenkins-cli.jar -s http://localhost:8080/ list-plugins | grep -e ')$' | awk '{ print $1 }' );
if [ ! -z "${UPDATE_LIST}" ]; then
    echo Updating Jenkins Plugins: ${UPDATE_LIST};
    java -jar /root/jenkins-cli.jar -s http://127.0.0.1:8080/ install-plugin ${UPDATE_LIST} ;
fi

# Install plugins for our Jenkins instance
printf '%s\n' 'Installing Jenkins Plugins'
for each in "
    sectioned-view
    workflow-aggregator
    join
    ws-cleanup
    git
    git-client
    github
    github-api
    dashboard-view
    parameterized-trigger
    run-condition
    build-with-parameters
    credentials
    plain-credentials
    ssh-agent
    scm-api
";
do
    java -jar /root/jenkins-cli.jar -s http://localhost:8080/ install-plugin $each ;
done

# Docker Permission Fix
# We need the jenkins user to have the docker group as its primary group in order to use docker as the jenkins user
usermod -a -G docker jenkins

# Change docker files to be owned by the docker group
#chown -R root:docker docker/

# Restarting Jenkins Server to install plugins and jobs
#java -jar /root/jenkins-cli.jar -s http://localhost:8080/ restart
service docker restart
service jenkins restart

until wget -O /root/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar; do
    echo "Trying to download jenkins-cli.jar attempt to check jenkins is backup and running."
    sleep 10
done

# Installing Terraform
echo "Installing Terraform"
mkdir -p /opt/terraform
wget https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip -O /opt/terraform/terraform_0.13.0_linux_amd64.zip
mv /usr/bin/terraform /usr/bin/terraform-old #failsafe
cd /opt/terraform ; unzip terraform_0.13.0_linux_amd64.zip
ln -s /opt/terraform/terraform /usr/bin/terraform

echo "# # # done # # #"
exit 0
