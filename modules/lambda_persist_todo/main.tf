


# data "archive_file" "_" {
#   type        = "zip"
#   source_file = "${path.root}/lambda/src/todo_persist/main.py"
#   output_path = "${path.root}/package/${var.environment}/todo_persist/${var.lambda_name}.zip"
# }

module "aws_iam" {
  source            = "../aws_iam"
  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  # assume_role_policy = file("${path.root}/policies/assume_role.json")
  # template           = file("${path.root}/policies/dynamo_db_crud_policy.json")
  # role_name          = "${var.lambda_name}-role"
  # policy_name        = "${var.lambda_name}-policy"
  # role_vars = {
  #   aws_dynamodb_table_arn = var.dynamodb_table
  # }
  assume_role_policy = file("${path.root}/policies/assume_role.json")
  template           = file("${path.root}/policies/sqs_dynamo_policy.json")
  role_name          = "${var.lambda_name}-role"
  policy_name        = "${var.lambda_name}-policy"
  role_vars = {
    aws-queue-arn          = var.source_arn
    aws_dynamodb_table_arn = var.dynamo_table_arn
  }
}

module "aws_lambda" {
  source = "../aws_lambda"

  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name
  invoke_by_event   = true

  function_name     = var.lambda_name
  file_name         = var.package_file
  package_s3_bucket = var.package_s3_bucket
  handler_name      = "main.lambda_handler"
  role_arn          = module.aws_iam.role_arn
  source_arn        = var.source_arn

  lambda_variables = {
    DYNAMO_TABLE_NAME : var.dynamo_table_name
  }
}

