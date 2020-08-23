# Terraform Automation
# @author Zlatin Etimov


# Keeping your terraform.state files locally or commited in version control is generally a bad idea.
# Setting Terraform to use "s3" as our "backend" to put state files into
terraform {
  backend "s3" {
  }
}

# This tells Terraform we will use AWS. Your key/secret is being set via env vars.
provider "aws" {
  # If you have other AWS accounts, use this profile marker to point to specific credentials.
#  profile = "your-profile-name"
  version = "~> 3.2.0"
  region = var.region
}

provider "template" {
  version = "~> 2.1.2"
}

# This is the entry point script for our jenkins instance. This installs jenkins and req deps.
data "template_file" "jenkins_userdata" {
  template = "${file("userdata.tpl")}"

  vars = {
    EnvName = "${var.env_name}"
    # The name of the bucket that will store our Jenkins resources. This was created in terraform-aws-init
    JenkinsBucket = "${var.s3prefix}-jenkins-files-${var.region}"
  }
}

# The EC2 instance to go spin up with a Debian AMI, userdata script installs Jenkins.
resource "aws_instance" "jenkins_ec2" {
  ami = lookup(var.aws_amis, var.region)
  instance_type = var.instance_type
  key_name = var.ssh_key_name
  vpc_security_group_ids = [
    "${aws_security_group.public.id}"
  ]
  subnet_id = element(aws_subnet.public.*.id, 0)
  associate_public_ip_address = true
  source_dest_check           = false
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  user_data                   = data.template_file.jenkins_userdata.rendered

  tags = {
    Name = "${var.env_name}-${var.region}"
    ManagedBy = "Terraform"
    IamInstanceRole = "${aws_iam_role.jenkins_iam_role.name}"
  }

  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "standard"
    volume_size = "250"
    # Safeguard for your jenkins and docker data in production
    delete_on_termination = "true"
  }
}

# This is our main AWS Virtual Private Cloud we will launch jenkins into.
resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "tf-${var.env_name}-vpc"
    ManagedBy = "Terraform"
  }
}

# This is so we can get an outside connection.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    ManagedBy = "Terraform"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

# Create a public subnet for each availability zone
resource "aws_subnet" "public" {
  count = length(split(",",var.availability_zones))
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index+1)
  map_public_ip_on_launch = true
  availability_zone = element(split(",",var.availability_zones), count.index)

  tags = {
    Name = "${format("tf-aws-${var.env_name}-public-%03d", count.index+1)}"
    ManagedBy = "Terraform"
  }
}

# Create a private subnet for each availability zone
resource "aws_subnet" "private" {
  count = length(split(",",var.availability_zones))
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 6, count.index+1)
  map_public_ip_on_launch = false
  availability_zone = element(split(",",var.availability_zones), count.index)

  tags = {
    Name = "${format("tf-aws-${var.env_name}-private-%03d", count.index+1)}"
    ManagedBy = "Terraform"
  }
}

resource "aws_db_subnet_group" "rds" {
  name        = "tf-${var.env_name}-rds-subnet-group"
  description = "RDS subnet group"
  subnet_ids  = aws_subnet.private.*.id

  tags = {
    Name = "tf-${var.env_name}-rds-subnet-group"
    ManagedBy = "Terraform"
  }
}

# Our default security group to access the instances over SSH and HTTP
resource "aws_security_group" "public" {
  name = "tf-${var.env_name}-public-sg"
  description = "Managed By Terraform"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-${var.env_name}-public-sg"
    ManagedBy = "Terraform"
  }

 # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # Jenkins Web UI
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # Outbound Traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

# Our default security group to access the instance
resource "aws_security_group" "private" {
  name = "tf-${var.env_name}-private-sg"
  description = "Managed By Terraform"
  vpc_id = aws_vpc.main.id
  # Keep the instance private
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
  }

  # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # Outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tf-${var.env_name}-private-sg"
    ManagedBy = "Terraform"
  }
}

# A PostgreSQL Database
resource "aws_db_instance" "postgresql-db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "11.6"
  instance_class       = "db.t2.micro"
  name                 = var.database_name
  username             = var.database_username
  password             = "random_string.postgress_password.result"
  identifier           = var.database_name
  parameter_group_name = "default.postgres11"
  db_subnet_group_name = aws_db_subnet_group.rds.name
  iam_database_authentication_enabled = true
  vpc_security_group_ids    = ["${aws_security_group.private.id}"]
  port                      = 3306
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"

  tags = {
    Name = "${var.s3prefix}-postgres11-db-${var.region}"
    ManagedBy = "Terraform"
  }
}

#resource "aws_ssm_parameter" "database_url" {
#  name  = "/zlatin/${var.environment}/DATABASE_URL"
#  type  = "SecureString"
#  value = "postgres://${aws_db_instance.db.username}:${var.database_password}@${aws_db_instance.db.endpoint}/${aws_db_instance.db.name}"
#}

#resource "aws_ssm_parameter" "secret" {
#  name        = "/test/database/password/master"
#  description = "database master password"
#  type        = "SecureString"
#  value       = var.database_password
#
#  tags = {
#    environment = "test"
#  }

#
# RDS Password
#
resource "random_string" "postgress_password" {
  keepers = {
    # Generate a new password every time this module is run
    build = timestamp()
  }

  length           = 32
  special          = true
  override_special = "!#$%^&*()"
}

#
# KMS used to encrypt database user and password, and the database itself
#
resource "aws_kms_key" "postgres_kms" {
  description         = "${var.resource_prefix} postgres encryption key"
  enable_key_rotation = true

  tags = {
    TerraformStack = var.resource_prefix
  }
}

#
# Persist credentials to SSM for reference
#

locals {
  base_ssm_path = "/${var.environment}/database/postgresql/${var.database_name}"
}

resource "aws_ssm_parameter" "postgresql_username_ssm" {
  name        = "${local.base_ssm_path}/username"
  type        = "SecureString"
  value       = var.database_username
  description = "Database username of ${var.resource_prefix} postgres"
  key_id      = aws_kms_key.postgres_kms.arn
  tags = {
    Environment    = var.environment
    TerraformStack = var.resource_prefix
  }
}

resource "aws_ssm_parameter" "postgresql_password_ssm" {
  name        = "${local.base_ssm_path}/password"
  type        = "SecureString"
  value       = random_string.postgress_password.result
  description = "Database password of ${var.resource_prefix} postgres"
  key_id      = aws_kms_key.postgres_kms.arn
  tags = {
    Environment    = var.environment
    TerraformStack = var.resource_prefix
  }
}
