resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/app"
  retention_in_days = 14

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "${var.project_name}-error-filter"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/Errors"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name          = "${var.project_name}-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/Errors"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Fires when an ERROR appears in EC2 app logs"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Fires when the image processor Lambda throws an error"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.image_processor.function_name
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-ec2-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Fires when EC2 CPU stays above 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}
