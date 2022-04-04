
#output
output "lambda_api_todo_name" {
  value = module.lambda_api_todo.lambda_arn
}
output "lambda_persist_todo_name" {
  value = module.lambda_persist_todo.lambda_arn
}

output "dynamodb_name" {
  value = "${aws_dynamodb_table._.name}(${aws_dynamodb_table._.arn})"
}

output "sqs_name" {
  value = "${aws_sqs_queue._.name}(${aws_sqs_queue._.arn})"
}

output "api_url" {
  value = module.lambda_api_todo.api_url
}

output "lambda_source_bucket" {
  value = aws_s3_bucket.lambda_bucket.bucket
}


