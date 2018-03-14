resource "aws_iam_role" "int_tableau" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com",
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "int_tableau" {
  role = "${aws_iam_role.int_tableau.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ssm:GetParameter"
      ],
      "Resource": [
        "arn:aws:ssm:eu-west-2:*:parameter/addomainjoin"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "int_tableau" {
  role = "${aws_iam_role.int_tableau.name}"
}
