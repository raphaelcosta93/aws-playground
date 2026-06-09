resource "null_resource" "lambda_dependencies" {
  triggers = {
    package_json = filemd5("${path.module}/../lambda/package.json")
  }

  provisioner "local-exec" {
    command     = "rm -rf node_modules && npm install"
    working_dir = "${path.module}/../lambda"
    environment = {
      npm_config_os   = "linux"
      npm_config_cpu  = "x64"
      npm_config_libc = "glibc"
    }
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda.zip"

  depends_on = [null_resource.lambda_dependencies]
}

resource "aws_lambda_function" "image_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-image-processor"
  role             = aws_iam_role.app_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      S3_BUCKET    = aws_s3_bucket.app.id
      DYNAMO_TABLE = aws_dynamodb_table.images.name
    }
  }

  tags = {
    Name      = "${var.project_name}-image-processor"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.app.arn
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.app.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "images/original/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
