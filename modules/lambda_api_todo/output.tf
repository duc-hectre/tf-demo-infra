output "lambda_arn" {
  value = module.aws_lambda.lambda_arn
}

output "api_url" {
  value = module.aws_api_gateway.api_execution_arn
}
