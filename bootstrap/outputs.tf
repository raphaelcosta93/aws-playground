output "tfstate_bucket_name" {
  description = "Name of the Terraform state bucket — paste this into main/providers.tf backend block"
  value       = aws_s3_bucket.tfstate.id
}

output "dynamodb_lock_table" {
  description = "Name of the DynamoDB lock table — paste this into main/providers.tf backend block"
  value       = aws_dynamodb_table.tfstate_lock.name
}
