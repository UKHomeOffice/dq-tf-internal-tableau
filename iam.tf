resource "aws_iam_role" "int_tableau" {
  name               = "internal-tableau"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
                    "ec2.amazonaws.com",
                    "s3.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "int_tableau" {

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
        "arn:aws:ssm:eu-west-2:*:parameter/addomainjoin",
        "arn:aws:ssm:eu-west-2:*:parameter/int_tableau_hostname",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_server_username",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_server_password",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_s3_prefix",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_linux_ssh_private_key",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_linux_ssh_public_key",
        "arn:aws:ssm:eu-west-2:*:parameter/data_archive_tab_int_backup_url",
        "arn:aws:ssm:eu-west-2:*:parameter/data_archive_tab_int_backup_sub_directory",
        "arn:aws:ssm:eu-west-2:*:parameter/tab_int_repo_protocol",
        "arn:aws:ssm:eu-west-2:*:parameter/tab_int_repo_user",
        "arn:aws:ssm:eu-west-2:*:parameter/tab_int_repo_host",
        "arn:aws:ssm:eu-west-2:*:parameter/tab_int_repo_port",
        "arn:aws:ssm:eu-west-2:*:parameter/tab_int_repo_org",
        "arn:aws:ssm:eu-west-2:*:parameter/tab_int_repo_name",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_admin_username",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_admin_password",
        "arn:aws:ssm:eu-west-2:*:parameter/gp_db_user_wsr",
      	"arn:aws:ssm:eu-west-2:*:parameter/tableau_server_repository_username",
	      "arn:aws:ssm:eu-west-2:*:parameter/tableau_server_repository_password",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_openid_provider_client_id",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_openid_client_secret",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_openid_provider_config_url",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_openid_tableau_server_external_url",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_staging_openid_provider_client_id",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_staging_openid_client_secret",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_staging_openid_provider_config_url",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_staging_openid_tableau_server_external_url",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_product_key",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_notprod_product_key",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_publish_datasources",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_int_publish_workbooks",
        "arn:aws:ssm:eu-west-2:*:parameter/rds_internal_tableau_postgres_endpoint",
        "arn:aws:ssm:eu-west-2:*:parameter/rds_internal_tableau_service_username",
        "arn:aws:ssm:eu-west-2:*:parameter/rds_internal_tableau_service_password",
        "arn:aws:ssm:eu-west-2:*:parameter/tableau_config_smtp_int"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "ssm:PutParameter"
      ],
      "Resource": "arn:aws:ssm:eu-west-2:*:parameter/data_archive_tab_int_backup_sub_directory"
    },
    {
      "Effect": "Allow",
      "Action": [
         "ec2:ModifyInstanceMetadataOptions"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "int_tableau" {
  role       = aws_iam_role.int_tableau.id
  policy_arn = aws_iam_policy.int_tableau.arn
}

resource "aws_iam_policy" "int_tableau_s3" {

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": [
        "${var.s3_archive_bucket}",
        "arn:aws:s3:::${var.s3_httpd_config_bucket}"
        ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "${var.s3_archive_bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${var.s3_httpd_config_bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
        ],
      "Resource": [
        "${var.s3_archive_bucket_key}",
        "${var.s3_httpd_config_bucket_key}"
        ]
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "int_tableau_s3" {
  role       = aws_iam_role.int_tableau.id
  policy_arn = aws_iam_policy.int_tableau_s3.arn
}

resource "aws_iam_instance_profile" "int_tableau" {
  role = aws_iam_role.int_tableau.name
}

resource "aws_iam_role_policy_attachment" "cloud_watch_agent" {
  role       = aws_iam_role.int_tableau.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "dq_tf_infra_write_to_cw" {
  role       = aws_iam_role.int_tableau.id
  policy_arn = "arn:aws:iam::${var.account_id[var.environment]}:policy/dq-tf-infra-write-to-cw"
}
