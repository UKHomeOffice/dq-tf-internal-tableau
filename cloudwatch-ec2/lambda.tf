data "archive_file" "lambda_slack_zip" {
  type        = "zip"
  source_dir  = "${local.path_module}/lambda/slack"
  output_path = "${local.path_module}/lambda/slack/package/lambda.zip"
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ec2.arn
}

resource "aws_lambda_function" "lambda_slack" {
  filename         = "${path.module}/lambda/slack/package/lambda.zip"
  function_name    = "${var.pipeline_name}-lambda-slack-${var.environment}"
  role             = aws_iam_role.lambda_role_slack.arn
  handler          = "slack.lambda_handler"
  source_code_hash = data.archive_file.lambda_slack_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "60"

  tags = {
    Name = "lambda-slack-${var.pipeline_name}-${var.environment}"
  }

  depends_on = [aws_iam_role.lambda_role_slack]

  # lifecycle {
  #   ignore_changes = [
  #     filename,
  #     last_modified,
  #     source_code_hash,
  #   ]
  # }

}

resource "aws_iam_role_policy" "lambda_policy_slack" {
  name = "${var.pipeline_name}-lambda-policy-slack-${var.environment}"
  role = aws_iam_role.lambda_role_slack.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/slack_notification_webhook"
	  ]
    }
  ]
}
EOF


  depends_on = [aws_iam_role.lambda_role_slack]
}

resource "aws_iam_role" "lambda_role_slack" {
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
    Name = "iam-lambda-slack-${local.naming_suffix}"
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group_slack" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_slack.function_name}"
  retention_in_days = 14

  tags = {
    Name = "lambda-log-group-slack-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_logging_policy_slack" {
  name        = "${var.pipeline_name}-lambda-logging-policy-slack-${var.environment}"
  path        = "/"
  description = "IAM policy for logging from a lambda"

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
        "${aws_cloudwatch_log_group.lambda_log_group_slack.arn}",
        "${aws_cloudwatch_log_group.lambda_log_group_slack.arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_logging_policy_attachment_slack" {
  role       = aws_iam_role.lambda_role_slack.name
  policy_arn = aws_iam_policy.lambda_logging_policy_slack.arn
}
