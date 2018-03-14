locals {
  naming_suffix = "internal-tableau-${var.naming_suffix}"
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

  user_data = <<EOF
  <powershell>
  $password = aws --region eu-west-2 ssm get-parameter --name addomainjoin --query 'Parameter.Value' --output text --with-decryption
  $username = "DQ\domain.join"
  $credential = New-Object System.Management.Automation.PSCredential($username,$password)
  $instanceID = $instanceID = aws --region eu-west-2 ssm get-parameter --name int_tableau_hostname --query 'Parameter.Value' --output text --with-decryption
  Add-Computer -DomainName DQ.HOMEOFFICE.GOV.UK -OUPath "OU=Computers,OU=dq,DC=dq,DC=homeoffice,DC=gov,DC=uk" -NewName $instanceID -Credential $credential -Force -Restart
  </powershell>
EOF

  tags = {
    Name = "ec2-${local.naming_suffix}"
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
