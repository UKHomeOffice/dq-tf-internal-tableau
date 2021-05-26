resource "aws_iam_role" "lambda_monitor" {
  name = "${var.monitor_name}-${var.environment}-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "iam-${var.monitor_name}-lambda-${var.naming_suffix}"
  }
}

resource "aws_iam_role_policy" "lambda_monitor_policy" {
  name = "${var.monitor_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_monitor.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.input_bucket}-${var.environment}",
        "arn:aws:s3:::${var.input_bucket}-${var.environment}/*"]
    },
    {
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Effect": "Allow",
      "Resource": "${var.kms_key_s3[var.environment]}"
    },
    {
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:${var.region}:${var.account_id[var.environment]}:parameter/slack_notification_webhook"
    }
  ]
}
EOF
}

data "archive_file" "lambda_monitor_zip" {
  type        = "zip"
  source_dir  = "${var.path_module}/lambda/monitor/code"
  output_path = "${var.path_module}/lambda/monitor/package/lambda_monitor.zip"
}

resource "aws_lambda_function" "lambda_monitor" {
  filename         = "${path.module}/lambda/monitor/package/lambda_monitor.zip"
  function_name    = "${var.monitor_name}-${var.environment}-lambda"
  role             = aws_iam_role.lambda_monitor.arn
  handler          = "monitor.lambda_handler"
  source_code_hash = data.archive_file.lambda_monitor_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "2048"

  environment {
    variables = {
      bucket_name    = "${var.input_bucket}-${var.environment}"
      path_          = "${var.backup_path}"
      threashold_min = "${var.monitor_lambda_run}"
    }
  }

  tags = {
    Name = "lambda-${var.monitor_name}-${var.naming_suffix}"
  }
}

resource "aws_cloudwatch_log_group" "lambda_monitor" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_monitor.function_name}"
  retention_in_days = 90

  tags = {
    Name = "log-lambda-${var.monitor_name}-${var.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_monitor_logging" {
  name        = "${var.monitor_name}-${var.environment}-lambda-logging"
  path        = "/"
  description = "IAM policy for monitor lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.lambda_monitor.arn}",
        "${aws_cloudwatch_log_group.lambda_monitor.arn}/*"
      ],
      "Effect": "Allow"
    },
    {
       "Action": "logs:CreateLogGroup",
       "Resource": "arn:aws:logs:${var.region}:${var.account_id[var.environment]}:*",
       "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_monitor_logs" {
  role       = aws_iam_role.lambda_monitor.name
  policy_arn = aws_iam_policy.lambda_monitor_logging.arn
}

resource "aws_cloudwatch_event_rule" "monitor_backup" {
  name                = "${var.monitor_name}-${var.environment}-cw-event-rule"
  description         = "Fires 9AM Mon - Fri)"
  schedule_expression = "cron(9 0 ? * MON-FRI *)"
  is_enabled          = var.environment == "prod" ? "true" : "true"
}

resource "aws_cloudwatch_event_target" "monitor_backup" {
  rule = aws_cloudwatch_event_rule.monitor_backup.name
  arn  = aws_lambda_function.lambda_monitor.arn
}

resource "aws_lambda_permission" "monitor_backup_cw_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monitor_backup.arn
}
