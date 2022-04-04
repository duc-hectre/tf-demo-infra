terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 3.27"
    }
  }
  # backend "s3" {
  #   region  = "ap-southeast-1"
  #   profile = "srvadm"
  #   bucket  = "tf_demo_bucket"
  # }
}

provider "aws" {
  profile = "srvadm"
  region  = "ap-southeast-1"
}

locals {
  resource_name_prefix = "${var.environment}-${var.resource_tag_name}"

  tags = {
    Environment = var.environment
    Name        = var.resource_tag_name
  }
}

#dynamodb

resource "aws_dynamodb_table" "_" {
  name           = "${local.resource_name_prefix}-table"
  hash_key       = "id"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_sqs_queue" "_" {
  name                      = "${local.resource_name_prefix}-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  # redrive_policy = jsonencode({
  #   deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
  #   maxReceiveCount     = 4
  # })
  # redrive_allow_policy = jsonencode({
  #   redrivePermission = "byQueue",
  #   sourceQueueArns   = ["${aws_sqs_queue.terraform_queue_deadletter.arn}"]
  # })

  tags = {
    Environment = "production"
  }
}

module "lambda_api_todo" {
  source = "./modules/lambda_api_todo"

  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  lambda_name       = "todo-handler"
  api_name          = "tf-sam-api-todo"
  queue_arn         = aws_sqs_queue._.arn
  dynamo_table_arn  = aws_dynamodb_table._.arn
  queue_url         = aws_sqs_queue._.url
  dynamo_table_name = aws_dynamodb_table._.name
  package_s3_bucket = aws_s3_bucket.lambda_bucket.bucket
  package_file      = "tf-demo/28d8cf641ad191a521f46ff4eb39403f"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "${local.resource_name_prefix}-lambda-source-bucket"
}

resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

module "lambda_persist_todo" {
  source = "./modules/lambda_persist_todo"

  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  lambda_name       = "todo-persist"
  dynamo_table_arn  = aws_dynamodb_table._.arn
  source_arn        = aws_sqs_queue._.arn
  dynamo_table_name = aws_dynamodb_table._.name
  package_s3_bucket = aws_s3_bucket.lambda_bucket.bucket
  package_file      = "tf-demo/bfc5ab6312ea2e99f4f7bff1f055e45e"
}


# module "aws_tf_cicd_pipeline" {
#   source = "./modules/aws_tf_cicd_pipeline"

#   environment       = var.environment
#   region            = var.region
#   resource_tag_name = var.resource_tag_name

#   cicd_name                      = "tf-cicd-todo"
#   codestar_connector_credentials = var.codestar_connector_credentials
#   pipeline_artifact_bucket       = "tf-cicd-todo-artifact-bucket"
# }
