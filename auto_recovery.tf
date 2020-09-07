data "aws_region" "current" {}


resource "aws_cloudwatch_metric_alarm" "status_check_failed_instance_alarm_Tab_Int0" {
  alarm_name                = "EC2-High-Status-Check-Failed-Instance-Tab-Int0"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "3"
  metric_name               = "StatusCheckFailed_Instance"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Maximum"
  threshold                 = "1"
  alarm_description         = "This metric monitors failed instance status check on ec2"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = ["arn:aws:automate:${data.aws_region.current.name}:ec2:reboot"]

  dimensions = {
    InstanceId = aws_instance.int_tableau_linux[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_instance_alarm_Tab_Int1" {
  alarm_name                = "EC2-High-Status-Check-Failed-Instance-Tab-Int1"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "3"
  metric_name               = "StatusCheckFailed_Instance"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Maximum"
  threshold                 = "1"
  alarm_description         = "This metric monitors failed instance status check on ec2"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = ["arn:aws:automate:${data.aws_region.current.name}:ec2:reboot"]

  dimensions = {
    InstanceId = aws_instance.int_tableau_linux[1].id
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_instance_alarm_Tab_Int_Stg" {
  alarm_name                = "EC2-High-Status-Check-Failed-Instance-Tab-Int-Stg"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "3"
  metric_name               = "StatusCheckFailed_Instance"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Maximum"
  threshold                 = "1"
  alarm_description         = "This metric monitors failed instance status check on ec2"
  insufficient_data_actions = []
  actions_enabled           = "true"
  alarm_actions             = ["arn:aws:automate:${data.aws_region.current.name}:ec2:reboot"]

  dimensions = {
    InstanceId = aws_instance.int_tableau_linux[0].id
  }
}
