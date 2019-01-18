locals {
  naming_suffix          = "internal-tableau-${var.naming_suffix}"
  naming_suffix_v2018_03 = "internal-tableau-v2018-03-${var.naming_suffix}"
  naming_suffix_linux    = "internal-tableau-linux-${var.naming_suffix}"
}

resource "aws_instance" "int_tableau" {
  key_name                    = "${var.key_name}"
  ami                         = "${data.aws_ami.int_tableau.id}"
  instance_type               = "r4.4xlarge"
  iam_instance_profile        = "${aws_iam_instance_profile.int_tableau.id}"
  vpc_security_group_ids      = ["${aws_security_group.sgrp.id}"]
  associate_public_ip_address = false
  subnet_id                   = "${aws_subnet.subnet.id}"
  private_ip                  = "${var.dq_internal_dashboard_instance_ip}"
  monitoring                  = true

  user_data = <<EOF
  <powershell>
  $password = aws --region eu-west-2 ssm get-parameter --name addomainjoin --query 'Parameter.Value' --output text --with-decryption
  $username = "DQ\domain.join"
  $credential = New-Object System.Management.Automation.PSCredential($username,$password)
  $instanceID = aws --region eu-west-2 ssm get-parameter --name int_tableau_hostname --query 'Parameter.Value' --output text --with-decryption
  Add-Computer -DomainName DQ.HOMEOFFICE.GOV.UK -OUPath "OU=Computers,OU=dq,DC=dq,DC=homeoffice,DC=gov,DC=uk" -NewName $instanceID -Credential $credential -Force -Restart
  </powershell>
EOF

  tags = {
    Name = "ec2-${local.naming_suffix}"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      "user_data",
      "ami",
      "instance_type",
    ]
  }
}

resource "aws_instance" "int_tableau_blue" {
  key_name                    = "${var.key_name}"
  ami                         = "${data.aws_ami.int_tableau.id}"
  instance_type               = "r4.4xlarge"
  iam_instance_profile        = "${aws_iam_instance_profile.int_tableau.id}"
  vpc_security_group_ids      = ["${aws_security_group.sgrp.id}"]
  associate_public_ip_address = false
  subnet_id                   = "${aws_subnet.subnet.id}"
  private_ip                  = "${var.dq_internal_dashboard_blue_instance_ip}"
  monitoring                  = true

  user_data = <<EOF
  <powershell>
  $tsm_user = aws --region eu-west-2 ssm get-parameter --name tableau_server_username --query 'Parameter.Value' --output text --with-decryption
  [Environment]::SetEnvironmentVariable("tableau_tsm_user", $tsm_user, "Machine")
  $tsm_password = aws --region eu-west-2 ssm get-parameter --name tableau_server_password --query 'Parameter.Value' --output text --with-decryption
  [Environment]::SetEnvironmentVariable("tableau_tsm_password", $tsm_password, "Machine")
  $s3_bucket_name = "${var.s3_archive_bucket_name}"
  [Environment]::SetEnvironmentVariable("bucket_name", $s3_bucket_name, "Machine")
  $s3_bucket_sub_path = aws --region eu-west-2 ssm get-parameter --name tableau_int_s3_prefix --query 'Parameter.Value' --output text --with-decryption
  [Environment]::SetEnvironmentVariable("bucket_sub_path", $s3_bucket_sub_path, "Machine")
  $password = aws --region eu-west-2 ssm get-parameter --name addomainjoin --query 'Parameter.Value' --output text --with-decryption
  $username = "DQ\domain.join"
  $credential = New-Object System.Management.Automation.PSCredential($username,$password)
  $instanceID = aws --region eu-west-2 ssm get-parameter --name int_tableau_hostname --query 'Parameter.Value' --output text --with-decryption
  Add-Computer -DomainName DQ.HOMEOFFICE.GOV.UK -OUPath "OU=Computers,OU=dq,DC=dq,DC=homeoffice,DC=gov,DC=uk" -NewName $instanceID -Credential $credential -Force -Restart
  </powershell>
EOF

  tags = {
    Name = "ec2-${local.naming_suffix_v2018_03}"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      "user_data",
      "ami",
      "instance_type",
    ]
  }
}

resource "aws_instance" "int_tableau_linux" {
  key_name                    = "${var.key_name}"
  ami                         = "${data.aws_ami.int_tableau_linux.id}"
  instance_type               = "m5.4xlarge"
  iam_instance_profile        = "${aws_iam_instance_profile.int_tableau.id}"
  vpc_security_group_ids      = ["${aws_security_group.sgrp.id}"]
  associate_public_ip_address = false
  subnet_id                   = "${aws_subnet.subnet.id}"
  private_ip                  = "${var.dq_internal_dashboard_linux_instance_ip}"
  monitoring                  = true

  user_data = <<EOF
#!/bin/bash
echo "Hello world"

##Initialise TSM (finishes off Tableau Server install/config)
#/opt/tableau/tableau_server/packages/scripts.*/initialize-tsm --accepteula -f -a tableau_srv
#
#source /etc/profile.d/tableau_server.sh
#tsm register --file /tmp/install/tab_reg_file.json
#
#
#aws --region eu-west-2 ssm get-parameter --name tableau_linux_ssh_private_key --query 'Parameter.Value' --output text --with-decryption > /home/tableau_srv/.ssh/gitlab_key
#chmod 0400 /home/tableau_srv/.ssh/gitlab_key
#
#su - tableau_srv
#aws --region eu-west-2 ssm get-parameter --name tableau_linux_ssh_public_key --query 'Parameter.Value' --output text --with-decryption > /home/tableau_srv/.ssh/gitlab_key.pub
#chmod 0444 /home/tableau_srv/.ssh/gitlab_key.pub
#
#
##Get most recent Tableau backup from S3
##***get DATA_ARCHIVE_TAB_INT_BACKUP_URL from ParamStore***
#export DATA_ARCHIVE_TAB_INT_BACKUP_URL=`aws --region eu-west-2 ssm get-parameter --name DATA_ARCHIVE_TAB_INT_BACKUP_URL --query 'Parameter.Value' --output text`
#export LATEST_BACKUP_NAME=`aws s3 ls ${DATA_ARCHIVE_TAB_INT_BACKUP_URL} | tail -1 | awk '{print $4}'`
#aws s3 cp ${DATA_ARCHIVE_TAB_INT_BACKUP_URL}${LATEST_BACKUP_NAME} /home/tableau_srv/tableau_backups/${LATEST_BACKUP_NAME}
#
##As tableau_srv restore latest backup to Tableau Server
#su - tableau_srv
#export LATEST_BACKUP_NAME=`ls -1 /home/tableau_srv/tableau_backups/ | tail -1'`
#tsm stop && tsm maintenance restore --file /home/tableau_srv/tableau_backups/${LATEST_BACKUP_NAME}
#exit
#
#As tableau_srv, get latest code
su - tableau_srv
export TAB_INT_REPO_URL="NOT SET"
git clone ${TAB_INT_REPO_URL}
exit
#
##Publish the *required* workbook(s)/DataSource(s) - specified somehow...?
#
#DELETE the rest
#aws --region eu-west-2 ssm get-parameter --name gpadmin_public_key --query 'Parameter.Value' --output text --with-decryption >> /home/wherescape/.ssh/authorized_keys
#sudo touch /etc/profile.d/script_envs.sh
#sudo setfacl -m u:wherescape:rwx /etc/profile.d/script_envs.sh
#sudo -u wherescape echo "
#export BUCKET_NAME=`aws --region eu-west-2 ssm get-parameter --name DRT_BUCKET_NAME --query 'Parameter.Value' --output text --with-decryption`
#export EF_DB_HOST=`aws --region eu-west-2 ssm get-parameter --name ef_rds_dns_name --query 'Parameter.Value' --output text --with-decryption`
#export EF_DB_USER=`aws --region eu-west-2 ssm get-parameter --name EF_DB_USER --query 'Parameter.Value' --output text --with-decryption`
#export EF_DB=`aws --region eu-west-2 ssm get-parameter --name EF_DB --query 'Parameter.Value' --output text --with-decryption`
#export PGPASSWORD=`aws --region eu-west-2 ssm get-parameter --name ef_dbuser_password --query 'Parameter.Value' --output text --with-decryption`
#export DRT_AWS_ACCESS_KEY_ID=`aws --region eu-west-2 ssm get-parameter --name DRT_AWS_ACCESS_KEY_ID --query 'Parameter.Value' --output text --with-decryption`
#export DRT_AWS_SECRET_ACCESS_KEY=`aws --region eu-west-2 ssm get-parameter --name DRT_AWS_SECRET_ACCESS_KEY --query 'Parameter.Value' --output text --with-decryption`
#export KMS_ID=`aws --region eu-west-2 ssm get-parameter --name DRT_AWS_KMS_KEY_ID --query 'Parameter.Value' --output text --with-decryption`
#export DEBUG=`aws --region eu-west-2 ssm get-parameter --name DRT_AWS_DEBUG --query 'Parameter.Value' --output text --with-decryption`
#" > /etc/profile.d/script_envs.sh
#su -c "/etc/profile.d/script_envs.sh" - wherescape
#export DOMAIN_JOIN=`aws --region eu-west-2 ssm get-parameter --name addomainjoin --query 'Parameter.Value' --output text --with-decryption`
#yum -y install sssd realmd krb5-workstation adcli samba-common-tools expect
#sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
#systemctl reload sshd
#chkconfig sssd on
#systemctl start sssd.service
#echo "%Domain\\ Admins@dq.homeoffice.gov.uk ALL=(ALL:ALL) ALL" >>  /etc/sudoers
#expect -c "spawn realm join -U domain.join@dq.homeoffice.gov.uk DQ.HOMEOFFICE.GOV.UK; expect \"*?assword for domain.join@DQ.HOMEOFFICE.GOV.UK:*\"; send -- \"$DOMAIN_JOIN\r\" ; expect eof"
#systemctl restart sssd.service
#reboot
EOF

  tags = {
    Name = "ec2-${local.naming_suffix}"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      "user_data",
      "ami",
      "instance_type",
    ]
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = "${var.apps_vpc_id}"
  cidr_block        = "${var.dq_internal_dashboard_subnet_cidr}"
  availability_zone = "${var.az}"

  tags {
    Name = "subnet-${local.naming_suffix}"
  }
}

resource "aws_route_table_association" "internal_tableau_rt_association" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${var.route_table_id}"
}

resource "aws_security_group" "sgrp" {
  vpc_id = "${var.apps_vpc_id}"

  ingress {
    from_port = "${var.http_from_port}"
    to_port   = "${var.http_to_port}"
    protocol  = "${var.http_protocol}"

    cidr_blocks = [
      "${var.dq_ops_ingress_cidr}",
      "${var.acp_prod_ingress_cidr}",
      "${var.peering_cidr_block}",
    ]
  }

  ingress {
    from_port = "${var.RDP_from_port}"
    to_port   = "${var.RDP_to_port}"
    protocol  = "${var.RDP_protocol}"

    cidr_blocks = [
      "${var.dq_ops_ingress_cidr}",
      "${var.peering_cidr_block}",
    ]
  }

  ingress {
    from_port = "${var.TSM_from_port}"
    to_port   = "${var.TSM_to_port}"
    protocol  = "${var.http_protocol}"

    cidr_blocks = [
      "${var.dq_ops_ingress_cidr}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sg-${local.naming_suffix}"
  }
}
