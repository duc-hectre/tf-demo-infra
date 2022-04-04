# -----------------------------------------------------------------------------
# Variables: General
# -----------------------------------------------------------------------------

variable "environment" {
  description = "AWS resource environment/prefix"
}

variable "region" {
  description = "AWS region"
}

variable "resource_tag_name" {
  description = "Resource tag name for cost tracking"
}


# -----------------------------------------------------------------------------
# Variables: Lambda
# -----------------------------------------------------------------------------

variable "lambda_name" {
  description = "AWS resource name"
}
# variable "api_name" {
#   description = "AWS resource name"
# }

variable "dynamo_table_arn" {
  description = "dynamodb-table to grant permission to lambda"
}

variable "source_arn" {
  description = "event source arn to trigger lambda"
}

variable "dynamo_table_name" {
  description = "dynamo table name that lambda function uses to retreive data"
}

variable "package_s3_bucket" {
  description = "s3 bucket contains the lambda source"
}


variable "package_file" {
  description = "s3 bucket contains the lambda source"
}
