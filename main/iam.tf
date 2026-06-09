resource "aws_iam_role" "app_lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.app_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_s3_access" {
  name        = "${var.project_name}-lambda-s3-policy"
  description = "Allow Lambda to read and write the app S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app.arn,
          "${aws_s3_bucket.app.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.app_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_access.arn
}

resource "aws_iam_policy" "lambda_dynamodb_access" {
  name        = "${var.project_name}-lambda-dynamodb-policy"
  description = "Allow Lambda to write image metadata to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.images.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.app_lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_access.arn
}

# --- EC2 IAM role + instance profile ---

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy" "ec2_s3_access" {
  name        = "${var.project_name}-ec2-s3-policy"
  description = "Allow EC2 to read and write the app S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app.arn,
          "${aws_s3_bucket.app.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_dynamodb_access" {
  name        = "${var.project_name}-ec2-dynamodb-policy"
  description = "Allow EC2 to read and write the images DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.images.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ec2_dynamodb_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_dynamodb_access.arn
}
