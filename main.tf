locals {
  naming_suffix       = "internal-tableau-${var.naming_suffix}"
  naming_suffix_linux = "internal-tableau-linux-${var.naming_suffix}"
}

#module "dq-lambda-run-command-ec2" {
#  source             = "github.com/UKHomeOffice/dq-lambda-run-command-ec2"
#  count_tag          = "${var.environment == "prod" ? "0" : "0"}"
#  namespace          = "${var.environment}"
#  instance_id        = "${aws_instance.int_tableau_linux.id}"
#  ip_address         = ""
#  ssh_user           = "centos"
#  command            = "hostname"
#  naming_suffix      = "${var.naming_suffix}"
#  lambda_subnet      = "${var.lambda_subnet}"
#  lambda_subnet_az2  = "${var.lambda_subnet_az2}"
#  security_group_ids = "${var.security_group_ids}"
#}


# module "ec2_alarms_int_tableau" {
#   source          = "./cloudwatch-ec2/"
#   naming_suffix   = local.naming_suffix
#   environment     = var.environment
#   pipeline_name   = "int_tableau"
#   ec2_instance_id = aws_instance.int_tableau_linux[0].id
# }

resource "aws_instance" "int_tableau_linux" {
  count                       = var.environment == "prod" ? "2" : "2"
  key_name                    = var.key_name
  ami                         = data.aws_ami.int_tableau_linux.id
  instance_type               = var.environment == "prod" ? "r5.4xlarge" : "r5.2xlarge"
  iam_instance_profile        = aws_iam_instance_profile.int_tableau.id
  vpc_security_group_ids      = [aws_security_group.sgrp.id]
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.subnet.id
  private_ip                  = element(var.dq_internal_dashboard_instance_ip, count.index)
  monitoring                  = true

  user_data = <<EOF
#!/bin/bash

set -e

#log output from this user_data script
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1

# start the cloud watch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -s -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

echo "#Mount filesystem - /var/opt/tableau/"
mkfs.xfs /dev/nvme2n1
mkdir -p /var/opt/tableau/
mount /dev/nvme2n1 /var/opt/tableau
echo '/dev/nvme2n1 /var/opt/tableau xfs defaults 0 0' >> /etc/fstab

export PATH=$PATH:/usr/local/bin

echo "Enforcing imdsv2 on ec2 instance"
curl http://169.254.169.254/latest/meta-data/instance-id | xargs -I {} aws ec2 modify-instance-metadata-options --instance-id {} --http-endpoint enabled --http-tokens required

echo "#Pull values from Parameter Store and save to profile"
touch /home/tableau_srv/env_vars.sh
echo "
export TABLEAU_ENVIRONMENT=internal
export TABLEAU_REPO_ENVIRONMENT=internal
export S3_HTTPD_CONFIG_BUCKET=${var.s3_httpd_config_bucket}
export DATA_ARCHIVE_TAB_BACKUP_URL=`aws --region eu-west-2 ssm get-parameter --name data_archive_tab_int_backup_url --query 'Parameter.Value' --output text`
export TAB_SRV_USER=`aws --region eu-west-2 ssm get-parameter --name tableau_server_username --query 'Parameter.Value' --output text`
export TAB_SRV_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name tableau_server_password --query 'Parameter.Value' --output text --with-decryption`
export TAB_ADMIN_USER=`aws --region eu-west-2 ssm get-parameter --name tableau_admin_username --query 'Parameter.Value' --output text`
export TAB_ADMIN_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name tableau_admin_password --query 'Parameter.Value' --output text --with-decryption`
export TAB_TABSVR_REPO_USER=`aws --region eu-west-2 ssm get-parameter --name tableau_server_repository_username --query 'Parameter.Value' --output text`
export TAB_TABSVR_REPO_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name tableau_server_repository_password --query 'Parameter.Value' --output text --with-decryption`
export TAB_PRODUCT_KEY=`aws --region eu-west-2 ssm get-parameter --name tableau_int_product_key --query 'Parameter.Value' --output text --with-decryption`
export TAB_PRODUCT_KEY_NP=`aws --region eu-west-2 ssm get-parameter --name tableau_notprod_product_key --query 'Parameter.Value' --output text --with-decryption`
export RDS_POSTGRES_ENDPOINT=`aws --region eu-west-2 ssm get-parameter --name rds_internal_tableau_postgres_endpoint --query 'Parameter.Value' --output text`
export RDS_POSTGRES_SERVICE_USER=`aws --region eu-west-2 ssm get-parameter --name rds_internal_tableau_service_username --query 'Parameter.Value' --output text --with-decryption`
export RDS_POSTGRES_SERVICE_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name rds_internal_tableau_service_password --query 'Parameter.Value' --output text --with-decryption`
" > /home/tableau_srv/env_vars.sh

echo "#Load the env vars needed for this user_data script"
source /home/tableau_srv/env_vars.sh

echo "#Load the env vars when tableau_srv logs in"
cat >>/home/tableau_srv/.bashrc <<EOL
alias la='ls -laF'
alias atrdiag='echo "Run atrdiag as user tableau, not tableau_srv"'
alias tll='/home/tableau_srv/scripts/tableau-license-list.sh'
source /home/tableau_srv/env_vars.sh
EOL

echo "#Set password for tableau_srv"
echo $TAB_SRV_PASSWORD | passwd tableau_srv --stdin

echo "#Change ownership and permissions of tableau_srv files"
chown -R tableau_srv:tableau_srv /home/tableau_srv/
chmod 0644 /home/tableau_srv/env_vars.sh

echo "#Initialise TSM (finishes off Tableau Server install/config)"
sudo /opt/tableau/tableau_server/packages/scripts.*/initialize-tsm --accepteula -f -a tableau_srv

echo "#set aliases for tableau user"
cat >>/var/opt/tableau/tableau_server/.bashrc <<EOL
alias la='ls -laF'
# atrdiag only returns something useful when Full licenses are active, not when Trial license is in use
alias atrdiag='atrdiag -product "Tableau Server"'
EOL

echo "#sourcing tableau server envs - because this script is run as root not tableau_srv"
source /etc/profile.d/tableau_server.sh

#This block activates the NotProd Licenses in NotProd and the Tableau Internal License in Prod
echo "#License activation - Checking environment..."
echo "#Environment == '${var.environment}'"
if [ ${var.environment} == "notprod" ]; then
  echo "#TSM activate NOTPROD license as tableau_srv"
  tsm licenses activate --license-key "$TAB_PRODUCT_KEY_NP" --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD"
elif [ ${var.environment} == "prod" ]; then
  echo "#TSM activate PROD licenses as tableau_srv"
  tsm licenses activate --license-key "$TAB_PRODUCT_KEY"   --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD"
else
  echo "ERROR: Unexpected Environment"
fi

echo "#TSM register user details"
tsm register --file /tmp/install/tab_reg_file.json --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD"

echo "#TSM settings (add default)"
export CLIENT_ID=`aws --region eu-west-2 ssm get-parameter --name tableau_int_openid_provider_client_id --query 'Parameter.Value' --output text`
export CLIENT_SECRET=`aws --region eu-west-2 ssm get-parameter --name tableau_int_openid_client_secret --query 'Parameter.Value' --output text --with-decryption`
export CONFIG_URL=`aws --region eu-west-2 ssm get-parameter --name tableau_int_openid_provider_config_url --query 'Parameter.Value' --output text`
export EXTERNAL_URL=`aws --region eu-west-2 ssm get-parameter --name tableau_int_openid_tableau_server_external_url --query 'Parameter.Value' --output text`
export TAB_VERSION_NUMBER=`echo $PATH | awk -F customer '{print $2}' | cut -d \. -f2- | awk -F : '{print $1}'`
cat >/opt/tableau/tableau_server/packages/scripts.$TAB_VERSION_NUMBER/config-openid.json <<EOL
{
  "configEntities": {
    "openIDSettings": {
      "_type": "openIDSettingsType",
      "enabled": true,
      "clientId": "$CLIENT_ID",
      "clientSecret": "$CLIENT_SECRET",
      "configURL": "$CONFIG_URL",
      "externalURL": "$EXTERNAL_URL"
    }
  }
}
EOL
cat >/opt/tableau/tableau_server/packages/scripts.$TAB_VERSION_NUMBER/config-trusted-auth.json <<EOL
{
  "configEntities": {
    "trustedAuthenticationSettings": {
      "_type": "trustedAuthenticationSettingsType",
      "trustedHosts": [ "${var.haproxy_private_ip}","${var.haproxy_private_ip2}" ]
    }
  }
}
EOL

echo "#Pull values from Parameter Store and save smtp config locally"
aws --region eu-west-2 ssm get-parameter --name tableau_config_smtp_int --query 'Parameter.Value' --output text --with-decryption > /opt/tableau/tableau_server/packages/scripts.$TAB_VERSION_NUMBER/config-smtp.json

tsm settings import -f /opt/tableau/tableau_server/packages/scripts.*/config.json
tsm settings import -f /opt/tableau/tableau_server/packages/scripts.*/config-openid.json
tsm settings import -f /opt/tableau/tableau_server/packages/scripts.*/config-trusted-auth.json
tsm settings import -f /opt/tableau/tableau_server/packages/scripts.*/config-smtp.json

echo "#TSM increase extract timeout - to 12 hours (=43,200 seconds)"
tsm configuration set -k backgrounder.querylimit -v 43200

# echo "#TSM configure alerting emails"
tsm configuration set -k  storage.monitoring.email_enabled -v true

echo "#TSM configure access to peering proxies"
tsm configuration set -k wgserver.systeminfo.allow_referrer_ips -v ${var.haproxy_private_ip},${var.haproxy_private_ip2}

echo "#TSM apply pending changes for backgrounder"
tsm pending-changes apply

echo "#TSM initialise & start server"
tsm initialize --start-server --request-timeout 1800

echo "#Set the number of backgrounder processes to 4 once initialised"
tsm topology set-process -n node1 -pr backgrounder -c 4

echo "#TSM apply pending changes for backgrounder"
tsm pending-changes apply

echo "#Enable Tableau Repo Access"
tsm data-access repository-access enable --repository-username "$TAB_TABSVR_REPO_USER" --repository-password "$TAB_TABSVR_REPO_PASSWORD" --ignore-prompt --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD" 

# Always restore from Blue
export BACKUP_LOCATION="$DATA_ARCHIVE_TAB_BACKUP_URL/blue/"

echo "#Get most recent Tableau backup from S3"
export LATEST_BACKUP_NAME=`aws s3 ls $BACKUP_LOCATION | tail -1 | awk '{print $4}'`
aws s3 cp $BACKUP_LOCATION$LATEST_BACKUP_NAME /var/opt/tableau/tableau_server/data/tabsvc/files/backups/$LATEST_BACKUP_NAME

echo "#Restore latest backup to Tableau Server"
tsm stop --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD" && tsm maintenance restore --file $LATEST_BACKUP_NAME --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD" && tsm start --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD"

echo "#Mount filesystem - /var/log/"
mkfs.xfs /dev/nvme1n1
mkdir -p /mnt/var/log/
mount /dev/nvme1n1 /mnt/var/log
rsync -a /var/log/ /mnt/var/log
semanage fcontext -a -t var_t "/mnt/var" && semanage fcontext -a -e /var/log /mnt/var/log && restorecon -R -v /mnt/var
echo '/dev/nvme1n1 /var/log xfs defaults 0 0' >> /etc/fstab
umount /mnt/var/log/

reboot

EOF


  tags = {
    Name = "ec2-${local.naming_suffix_linux}"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      user_data,
      ami,
      instance_type,
    ]
  }
}

resource "aws_instance" "int_tableau_linux_staging" {
  count                       = var.environment == "prod" ? "1" : "0"
  key_name                    = var.key_name
  ami                         = data.aws_ami.int_tableau_linux.id
  instance_type               = "r5.4xlarge" # "c5.4xlarge"
  iam_instance_profile        = aws_iam_instance_profile.int_tableau.id
  vpc_security_group_ids      = [aws_security_group.sgrp.id]
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.subnet.id
  private_ip                  = element(var.dq_internal_staging_dashboard_instance_ip, count.index)
  monitoring                  = true

  user_data = <<EOF
#!/bin/bash

set -e

#log output from this user_data script
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1

echo "#Mount filesystem - /var/opt/tableau/"
mkfs.xfs /dev/nvme2n1
mkdir -p /var/opt/tableau/
mount /dev/nvme2n1 /var/opt/tableau
echo '/dev/nvme2n1 /var/opt/tableau xfs defaults 0 0' >> /etc/fstab

echo "Enforcing imdsv2 on ec2 instance"
curl http://169.254.169.254/latest/meta-data/instance-id | xargs -I {} aws ec2 modify-instance-metadata-options --instance-id {} --http-endpoint enabled --http-tokens required

echo "#Pull values from Parameter Store and save to profile"
touch /home/tableau_srv/env_vars.sh
echo "
export TABLEAU_ENVIRONMENT=staging
export TABLEAU_REPO_ENVIRONMENT=internal_staging
export S3_HTTPD_CONFIG_BUCKET=${var.s3_httpd_config_bucket}
export DATA_ARCHIVE_TAB_BACKUP_URL=`aws --region eu-west-2 ssm get-parameter --name data_archive_tab_int_backup_url --query 'Parameter.Value' --output text`
export TAB_SRV_USER=`aws --region eu-west-2 ssm get-parameter --name tableau_server_username --query 'Parameter.Value' --output text`
export TAB_SRV_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name tableau_server_password --query 'Parameter.Value' --output text --with-decryption`
export TAB_ADMIN_USER=`aws --region eu-west-2 ssm get-parameter --name tableau_admin_username --query 'Parameter.Value' --output text`
export TAB_ADMIN_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name tableau_admin_password --query 'Parameter.Value' --output text --with-decryption`
export TAB_TABSVR_REPO_USER=`aws --region eu-west-2 ssm get-parameter --name tableau_server_repository_username --query 'Parameter.Value' --output text`
export TAB_TABSVR_REPO_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name tableau_server_repository_password --query 'Parameter.Value' --output text --with-decryption`
export TAB_PRODUCT_KEY=`aws --region eu-west-2 ssm get-parameter --name tableau_int_product_key --query 'Parameter.Value' --output text --with-decryption`
export RDS_POSTGRES_ENDPOINT=`aws --region eu-west-2 ssm get-parameter --name rds_internal_tableau_postgres_endpoint --query 'Parameter.Value' --output text`
export RDS_POSTGRES_SERVICE_USER=`aws --region eu-west-2 ssm get-parameter --name rds_internal_tableau_service_username --query 'Parameter.Value' --output text --with-decryption`
export RDS_POSTGRES_SERVICE_PASSWORD=`aws --region eu-west-2 ssm get-parameter --name rds_internal_tableau_service_password --query 'Parameter.Value' --output text --with-decryption`
" > /home/tableau_srv/env_vars.sh

echo "#Load the env vars needed for this user_data script"
source /home/tableau_srv/env_vars.sh

echo "#Load the env vars when tableau_srv logs in"
cat >>/home/tableau_srv/.bashrc <<EOL
alias la='ls -laF'
alias atrdiag='echo "Run atrdiag as user tableau, not tableau_srv"'
alias tll='/home/tableau_srv/scripts/tableau-license-list.sh'
source /home/tableau_srv/env_vars.sh
EOL

echo "#Set password for tableau_srv"
echo $TAB_SRV_PASSWORD | passwd tableau_srv --stdin

echo "#Change ownership and permissions of tableau_srv files"
chown -R tableau_srv:tableau_srv /home/tableau_srv/
chmod 0644 /home/tableau_srv/env_vars.sh

echo "#Initialise TSM (finishes off Tableau Server install/config)"
/opt/tableau/tableau_server/packages/scripts.*/initialize-tsm --accepteula -f -a tableau_srv

echo "#set aliases for tableau user"
cat >>/var/opt/tableau/tableau_server/.bashrc <<EOL
alias la='ls -laF'
# atrdiag only returns something useful when Full licenses are active, not when Trial license is in use
alias atrdiag='atrdiag -product "Tableau Server"'
EOL

echo "#sourcing tableau server envs - because this script is run as root not tableau_srv"
source /etc/profile.d/tableau_server.sh

echo "#License activation - Checking environment..."
echo "#Environment == '${var.environment}'"
if [ ${var.environment} == "notprod" ]; then
  echo "#TSM activate TRIAL license as tableau_srv"
  tsm licenses activate --trial --username $TAB_SRV_USER --password $TAB_SRV_PASSWORD
elif [ ${var.environment} == "prod" ]; then
  echo "#TSM activate actual licenses as tableau_srv"
  tsm licenses activate --license-key "$TAB_PRODUCT_KEY"   --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD"
else
  echo "ERROR: Unexpected Environment"
fi

echo "#TSM register user details"
tsm register --file /tmp/install/tab_reg_file.json --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD"

echo "#TSM settings (add default)"
export CLIENT_ID=`aws --region eu-west-2 ssm get-parameter --name tableau_int_staging_openid_provider_client_id --query 'Parameter.Value' --output text`
export CLIENT_SECRET=`aws --region eu-west-2 ssm get-parameter --name tableau_int_staging_openid_client_secret --query 'Parameter.Value' --output text --with-decryption`
export CONFIG_URL=`aws --region eu-west-2 ssm get-parameter --name tableau_int_staging_openid_provider_config_url --query 'Parameter.Value' --output text`
export EXTERNAL_URL=`aws --region eu-west-2 ssm get-parameter --name tableau_int_staging_openid_tableau_server_external_url --query 'Parameter.Value' --output text`
export TAB_VERSION_NUMBER=`echo $PATH | awk -F customer '{print $2}' | cut -d \. -f2- | awk -F : '{print $1}'`
cat >/opt/tableau/tableau_server/packages/scripts.$TAB_VERSION_NUMBER/config-openid.json <<EOL
{
  "configEntities": {
    "openIDSettings": {
      "_type": "openIDSettingsType",
      "enabled": true,
      "clientId": "$CLIENT_ID",
      "clientSecret": "$CLIENT_SECRET",
      "configURL": "$CONFIG_URL",
      "externalURL": "$EXTERNAL_URL"
    }
  }
}
EOL
cat >/opt/tableau/tableau_server/packages/scripts.$TAB_VERSION_NUMBER/config-trusted-auth.json <<EOL
{
  "configEntities": {
    "trustedAuthenticationSettings": {
      "_type": "trustedAuthenticationSettingsType",
      "trustedHosts": [ "${var.haproxy_private_ip}","${var.haproxy_private_ip2}" ]
    }
  }
}
EOL
tsm settings import -f /opt/tableau/tableau_server/packages/scripts.*/config.json
tsm settings import -f /opt/tableau/tableau_server/packages/scripts.*/config-openid.json
tsm settings import -f /opt/tableau/tableau_server/packages/scripts.*/config-trusted-auth.json

echo "#TSM increase extract timeout - to 12 hours (=43,200 seconds)"
tsm configuration set -k backgrounder.querylimit -v 43200

echo "#TSM apply pending changes for backgrounder"
tsm pending-changes apply

echo "#TSM initialise & start server"
tsm initialize --start-server --request-timeout 1800

echo "#Set the number of backgrounder processes to 4 once initialised"
tsm topology set-process -n node1 -pr backgrounder -c 4

echo "#TSM apply pending changes for backgrounder"
tsm pending-changes apply

echo "#Enable Tableau Repo Access"
tsm data-access repository-access enable --repository-username "$TAB_TABSVR_REPO_USER" --repository-password "$TAB_TABSVR_REPO_PASSWORD" --ignore-prompt --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD" 

# Always restore from Blue
export BACKUP_LOCATION="$DATA_ARCHIVE_TAB_BACKUP_URL/blue/"

echo "#Get most recent Tableau backup from S3"
export LATEST_BACKUP_NAME=`aws s3 ls $BACKUP_LOCATION | tail -1 | awk '{print $4}'`
aws s3 cp $BACKUP_LOCATION$LATEST_BACKUP_NAME /var/opt/tableau/tableau_server/data/tabsvc/files/backups/$LATEST_BACKUP_NAME

echo "#Restore latest backup to Tableau Server"
tsm stop --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD" && tsm maintenance restore --file $LATEST_BACKUP_NAME --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD" && tsm start --username "$TAB_SRV_USER" --password "$TAB_SRV_PASSWORD"

echo "#Mount filesystem - /var/log/"
mkfs.xfs /dev/nvme1n1
mkdir -p /mnt/var/log/
mount /dev/nvme1n1 /mnt/var/log
rsync -a /var/log/ /mnt/var/log
semanage fcontext -a -t var_t "/mnt/var" && semanage fcontext -a -e /var/log /mnt/var/log && restorecon -R -v /mnt/var
echo '/dev/nvme1n1 /var/log xfs defaults 0 0' >> /etc/fstab
umount /mnt/var/log/

reboot

EOF


  tags = {
    Name = "ec2-staging-${local.naming_suffix}"
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      user_data,
      ami,
      instance_type,
    ]
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = var.apps_vpc_id
  cidr_block        = var.dq_internal_dashboard_subnet_cidr
  availability_zone = var.az

  tags = {
    Name = "subnet-${local.naming_suffix}"
  }
}

resource "aws_route_table_association" "internal_tableau_rt_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = var.route_table_id
}

resource "aws_security_group" "sgrp" {
  vpc_id = var.apps_vpc_id

  ingress {
    from_port = var.http_from_port
    to_port   = var.http_to_port
    protocol  = var.http_protocol

    cidr_blocks = [
      var.dq_ops_ingress_cidr,
      var.acp_prod_ingress_cidr,
      var.peering_cidr_block,
    ]
  }

  ingress {
    from_port = var.SSH_from_port
    to_port   = var.SSH_to_port
    protocol  = var.SSH_protocol

    cidr_blocks = [
      var.dq_ops_ingress_cidr,
    ]
  }

  ingress {
    from_port = var.TSM_from_port
    to_port   = var.TSM_to_port
    protocol  = var.http_protocol

    cidr_blocks = [
      var.dq_ops_ingress_cidr,
    ]
  }

  ingress {
    from_port = var.TAB_DB_to_port
    to_port   = var.TAB_DB_to_port
    protocol  = var.TAB_DB_protocol

    cidr_blocks = [
      var.dq_ops_ingress_cidr,
    ]
  }

  ingress {
    from_port = var.rds_from_port
    to_port   = var.rds_to_port
    protocol  = var.rds_protocol

    cidr_blocks = [
      var.dq_lambda_subnet_cidr,
      var.dq_lambda_subnet_cidr_az2,
    ]
  }

  ingress {
    from_port = var.SSH_from_port
    to_port   = var.SSH_to_port
    protocol  = var.SSH_protocol

    cidr_blocks = [
      var.dq_lambda_subnet_cidr,
      var.dq_lambda_subnet_cidr_az2,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${local.naming_suffix}"
  }
}
