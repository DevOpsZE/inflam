# If you want to make more than one Jenkins, this env_name is all that needs to change
variable "env_name" {
  description = "The name of the environment and resource namespacing."
}

# Where to place Jenkins
variable "region" {
  description = "The target AWS region"
}

# An s3 prefix (Your unique stack name)
variable "s3prefix" {
  description = "A unique s3 prefix to add for our bucket names"
}

# This is the root ssh key used for the ec2 instance
variable "ssh_key_name" {
  description = "The name of the preloaded root ssh key used to access AWS resources."
}

# Your best bet to find how many AZs there are is this list https://aws.amazon.com/about-aws/global-infrastructure/
# Assume it starts with "a" times how many AZs are available
variable "availability_zones" {
  description = "List of availability zones"
}

# The instance size we will use for Jenkins (I recommend large or higher for prod)
variable "instance_type" {
  description = "AWS instance type for Jenkins"
  default = "t2.medium"
}

# My personal perference is Debian, however I've seen others use CentOS/RedHat.
# If you do change the Linux Distro, you might need to change the intall cmds used.
# Amazon AMI is Debian Buster 10.5
variable "aws_amis" {
  type = map(string)
  default = {
    "af-south-1" = "ami-089c5d57a2e8ac3d8" 
    "ap-east-1" = "ami-966427e7"
    "ap-northeast-1" = "ami-0c8a2bdcc1d1b2c68"
    "ap-northeast-2" = "ami-0cfac5615120abb29"
    "ap-south-1" = "ami-0bed823f39b8d9828"
    "ap-southeast-1" = "ami-0003a0dda9240a8da"
    "ap-southeast-2" = "ami-08638c72b63ff353b"
    "ca-central-1" = "ami-09221e010aa5d4c12"
    "eu-central-1" = "ami-0e2b90ca04cae8da5"
    "eu-north-1" = "ami-0adddcb8c46f477b4"
    "eu-south-1" = "ami-04074fc16f26bd64b"
    "eu-west-1" = "ami-093185e1a0acee74b"
    "eu-west-2" = "ami-022bbe9ba628d3991"
    "eu-west-3" = "ami-0ff8ae01c38a9c3e9"
    "me-south-1" = "ami-03234c923e7f7d399"
    "sa-east-1" = "ami-026c0c168f9a2352e"
    "us-east-1" = "ami-05c0d7f3fffb419c8"
    "us-east-2" = "ami-03c3603751b46f895"
    "us-west-1" = "ami-04a823dd6e4f6fd52"
    "us-west-2" = "ami-0f7939d313699273c"
  }
}

# Database password
#variable "database_password" {
#  description = "database password from SSM"
#}

# Environment Variable 
#variable "environment" {
#  description = "env var for SSM "
#}

variable "environment" {
  type = string
}

variable "database_name" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "database_username" {
  default = "awsuser"
}
