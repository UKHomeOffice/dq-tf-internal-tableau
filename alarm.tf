resource "aws_cloudwatch_metric_alarm" "bitd_input_alarm" {
  alarm_name                = "bitd-input-error"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  unit                      = "Count"
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 86400
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "BITD INPUT Lambda has produced an Error"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.default.arn]

  dimensions = {
    FunctionName = "${aws_lambda_function.bitd_input[0].function_name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "createdb_resources_alarm" {
  alarm_name                = "createdb-resources-error"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  unit                      = "Count"
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 86400
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "CREATEDB RESOURCES Lambda has produced an Error"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.default.arn]

  dimensions = {
    FunctionName = "${aws_lambda_function.createdb_resources.function_name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "bitd_input_monitor" {
  alarm_name                = "bitd-input-monitor-error"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  datapoints_to_alarm       = "1"
  unit                      = "Count"
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = 86400
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "BITD INPUT MONITOR Resources Lambda has produced an Error"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = [aws_sns_topic.default.arn]

  dimensions = {
    FunctionName = "${aws_lambda_function.bitd_input_monitor.function_name}"
  }
}

resource "aws_sns_topic" "default" {
  name = var.pipeline_name
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.default.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = aws_sns_topic.default.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_slack.arn
}
