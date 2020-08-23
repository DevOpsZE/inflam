# Secret and key for AWS is set by env vars in bash scripts
provider "aws" {
  region = var.region
}

# This is the root ssh key pair on your machine we will be using to access our cloud provisioned resources.
resource "aws_key_pair" "root" {
  key_name = "root-ssh-key-${var.region}"
  public_key = var.ssh_key
}

# A bucket for the s3 logs related to the actual terraform states bucket
resource "aws_s3_bucket" "terraform-logs" {
  bucket = "${var.s3prefix}-terraform-states-logs-${var.region}"
  acl = "log-delivery-write"

  tags = {
    Name = "${var.s3prefix}-terraform-states-logs-${var.region}"
    ManagedBy = "Terraform"
  }
}

# The main terraform states bucket
resource "aws_s3_bucket" "terraform-states" {
  bucket = "${var.s3prefix}-terraform-states-${var.region}"
  acl = "private"

  # This is good for just in case the file gets corrupted or something bad.
  versioning {
    enabled = true
  }

  # Send all S3 logs to another bucket
  logging {
    target_bucket = aws_s3_bucket.terraform-logs.id
    target_prefix = "logs/"
  }

  tags = {
    Name = "${var.s3prefix}-terraform-states-${var.region}"
    ManagedBy = "Terraform"
  }
}

# A bucket for files to load onto our jenkins instance upon boot
resource "aws_s3_bucket" "jenkins-files" {
  bucket = "${var.s3prefix}-jenkins-files-${var.region}"
  acl = "private"

  tags = {
    Name = "${var.s3prefix}-jenkins-files-${var.region}"
    ManagedBy = "Terraform"
  }
}

# A bucket for static web hosting
resource "aws_s3_bucket" "s3-static-website" {
  bucket = "${var.s3prefix}-s3-static-website-${var.region}"
  acl = "public-read"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3prefix}-s3-static-website-${var.region}/*"
            ]
        }
    ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name = "${var.s3prefix}-s3-static-website-${var.region}"
    ManagedBy = "Terraform"
  }
}

# An ECR Repository
resource "aws_ecr_repository" "ecr-repository" {
  name = "${var.s3prefix}-ecr-repository-${var.region}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
    tags = {
    Name = "${var.s3prefix}-ecr-repository-${var.region}"
    ManagedBy = "Terraform"
  }
}
