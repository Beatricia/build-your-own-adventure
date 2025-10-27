terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################
# Variables
############################
variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "key_name" {
  # leave null if you don't have permission to create/use a keypair
  type    = string
  default = null
}

variable "docker_image" {
  description = "e.g. beatricianagit2222/go-backend:latest"
  type        = string
}

variable "site_bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
}

############################
# Default VPC + Subnet
############################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

############################
# Security Group
############################
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

############################
# EC2 (Amazon Linux 2)
############################
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    exec > /var/log/user-data.log 2>&1

    echo "=== START USER-DATA (AL2) ==="

    yum update -y
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker

    # IMDSv2 (tolerant if metadata not yet ready)
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
    PUBIP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      "http://169.254.169.254/latest/meta-data/public-ipv4" || true)
    echo "PUBIP=$PUBIP"

    docker pull ${var.docker_image} || true
    docker rm -f go-backend || true
    docker run -d --restart unless-stopped \
      -e BACKEND_BASE_URL="http://$PUBIP" \
      -p 80:8080 --name go-backend ${var.docker_image}

    echo "Containers:"
    docker ps

    # Local healthcheck loop
    for i in {1..20}; do
      code=$(curl -s -o /dev/null -w "%%{http_code}" http://127.0.0.1:80/api/LEGOdesigns || true)
      echo "Health attempt $i -> $code"
      [ "$code" = "200" ] && echo "OK" && break
      sleep 3
    done

    echo "=== END USER-DATA ==="
  EOF
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.al2.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  user_data                   = local.user_data

  tags = {
    Name = "go-backend-ec2"
  }
}

output "backend_public_url" {
  value = "http://${aws_instance.backend.public_ip}"
}

############################
# Frontend: S3 + CloudFront (OAC)
############################
resource "aws_s3_bucket" "site" {
  bucket        = var.site_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.site_bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  # --- ORIGIN 1: S3 for frontend ---
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # --- ORIGIN 2: EC2 for backend API ---
  origin {
    domain_name = aws_instance.backend.public_dns
    origin_id   = "api-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # CF -> EC2 over HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior -> S3 (static site)
  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    # Managed CachingOptimized policy ID
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Route API paths to EC2 (no caching, forward everything)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "api-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    # Disable caching for API
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "site_policy" {
  statement {
    sid = "AllowCloudFrontRead"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
}

output "frontend_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}
