output "app_bucket_name" {
  description = "Name of the app S3 bucket"
  value       = aws_s3_bucket.app.id
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.app_lambda_role.arn
}

output "sns_topic_arn" {
  description = "ARN of the alerts SNS topic"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB images table"
  value       = aws_dynamodb_table.images.name
}

output "alb_dns_name" {
  description = "ALB DNS name — open this in your browser"
  value       = aws_lb.main.dns_name
}
