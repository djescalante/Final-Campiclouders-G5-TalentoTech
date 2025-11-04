terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.region
}

# -----------------------------
# Data sources
# -----------------------------
data "aws_caller_identity" "current" {}

# -----------------------------
# DynamoDB Table
# -----------------------------
resource "aws_dynamodb_table" "contacts" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# -----------------------------
# IAM Role para EC2 de Elastic Beanstalk
# -----------------------------
resource "aws_iam_role" "eb_ec2_role" {
  name = var.eb_ec2_role_name != "" ? var.eb_ec2_role_name : "${var.app_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ddb_basic_access" {
  name = "ddbBasicAccess"
  role = aws_iam_role.eb_ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.contacts.arn
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = "${aws_dynamodb_table.contacts.arn}/index/*"
      }
    ]
  })
}

# Política adicional para acceso web (AWSElasticBeanstalkWebTier)
resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = var.eb_instance_profile_name != "" ? var.eb_instance_profile_name : "${aws_iam_role.eb_ec2_role.name}-profile"
  role = aws_iam_role.eb_ec2_role.name
}

# -----------------------------
# IAM Service Role para Elastic Beanstalk
# -----------------------------
resource "aws_iam_role" "eb_service_role" {
  name = "${var.app_name}-service-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "elasticbeanstalk.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_service_health" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "eb_service_managed" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

# -----------------------------
# S3 Bucket para deployments
# -----------------------------
resource "aws_s3_bucket" "eb_deployments" {
  bucket = lower("${var.app_name}-deployments-${data.aws_caller_identity.current.account_id}")
}

resource "aws_s3_bucket_public_access_block" "eb_deployments" {
  bucket = aws_s3_bucket.eb_deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------
# Crear archivo .zip de la aplicación
# -----------------------------
data "archive_file" "app" {
  type        = "zip"
  output_path = "${path.module}/app-deploy.zip"
  source_dir  = "${path.module}/app"
}

resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.eb_deployments.id
  key    = "app-${data.archive_file.app.output_md5}.zip"
  source = data.archive_file.app.output_path
  etag   = data.archive_file.app.output_md5
}

# -----------------------------
# Elastic Beanstalk Application & Environment
# -----------------------------
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = "EB app for Node.js + DynamoDB"
  
  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

data "aws_elastic_beanstalk_solution_stack" "nodejs" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 (.*) running Node.js 20$"
}

resource "aws_elastic_beanstalk_application_version" "default" {
  name        = "v-${data.archive_file.app.output_md5}"
  application = aws_elastic_beanstalk_application.app.name
  description = "Application version deployed by Terraform"
  bucket      = aws_s3_bucket.eb_deployments.id
  key         = aws_s3_object.app_version.id
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.nodejs.name
  version_label       = aws_elastic_beanstalk_application_version.default.name

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "TABLE_NAME"
    value     = var.table_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CORS_ORIGIN"
    value     = var.cors_origin
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = var.region
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MAX_RECORDS"
    value     = var.max_records
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}