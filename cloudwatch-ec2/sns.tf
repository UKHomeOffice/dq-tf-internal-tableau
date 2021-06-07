resource "aws_sns_topic" "ec2" {
  name = var.pipeline_name
}


resource "aws_sns_topic_policy" "ec2" {
  arn    = aws_sns_topic.ec2.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = aws_sns_topic.ec2.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_slack.arn
}
