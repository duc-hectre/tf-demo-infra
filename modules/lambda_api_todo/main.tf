


# data "archive_file" "_" {
#   type = "zip"
#   # source_file = "${path.root}/lambda/src/todo_handler/main.py"
#   source_dir  = "${path.root}/sam/todo_handler/.aws-sam/build/TodoFunction"
#   output_path = "${path.root}/package/${var.environment}/todo_handler/${var.lambda_name}.zip"
# }

module "aws_iam" {
  source            = "../aws_iam"
  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  assume_role_policy = file("${path.root}/policies/assume_role.json")
  template           = file("${path.root}/policies/sqs_dynamo_policy.json")
  role_name          = "${var.lambda_name}-role"
  policy_name        = "${var.lambda_name}-policy"
  role_vars = {
    aws-queue-arn          = var.queue_arn
    aws_dynamodb_table_arn = var.dynamo_table_arn
  }
}

module "aws_lambda" {
  source = "../aws_lambda"

  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  function_name     = var.lambda_name
  file_name         = var.package_file
  package_s3_bucket = var.package_s3_bucket
  handler_name      = "main.lambda_handler"
  role_arn          = module.aws_iam.role_arn
  source_arn        = "${module.aws_api_gateway.api_execution_arn}/*/*"
  lambda_variables = {
    SQS_URL : var.queue_url
    DYNAMO_TABLE_NAME : var.dynamo_table_name
  }
}

module "aws_api_gateway" {
  source = "../aws_api_gateway"

  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  api_name         = var.api_name
  resource_path    = "todo"
  http_method      = "ANY"
  lambda_uri       = module.aws_lambda.invoke_url
  deployment_state = var.environment
}
