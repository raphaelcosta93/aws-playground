variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "aws-learning"
}

variable "account_id" {
  description = "Your AWS account ID"
  type        = string
}
