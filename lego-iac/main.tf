# using aws as a provider
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# bucket name for frontend (must be globally unique!)
locals {
  site_bucket = "build-your-own-adventure-frontend-bucket"
}

# creating the bucket. It will store the build frontend files
resource "aws_s3_bucket" "site" {
  bucket = local.site_bucket
}

# public access config
resource "aws_s3_bucket_public_access_block" "pab" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# turning on static website hosting
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# public read policies, so it is available to get the files
data "aws_iam_policy_document" "public_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read.json
}

# security groups for the backend
# opens 22(SSH) and 8080 (Go API) to the world
resource "aws_security_group" "api_sg" {
  name        = "lego-api-sg"
  description = "Allow SSH and API"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# find an OS img (AMI) for the EC2 instance
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ec2 instance
resource "aws_instance" "api" {
  ami                    = data.aws_ami.amzn2.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.api_sg.id]
  key_name               = "lego-api-key"

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    yum update -y
    yum install -y git golang
    mkdir -p /opt/app && cd /opt/app
    git clone https://github.com/your-user/your-backend-repo.git app || true
    cd app
    /usr/bin/go build -o /usr/local/bin/lego-api
    mkdir -p /opt/app/uploads
    nohup /usr/local/bin/lego-api > /var/log/lego-api.log 2>&1 &
  EOF

  tags = { Name = "lego-api" }
}

output "frontend_website_url" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "backend_url" {
  value = "http://${aws_instance.api.public_ip}:8080"
}

