# pylint: disable=missing-docstring, line-too-long, protected-access, E1101, C0202, E0602, W0109
import unittest
import hashlib
from runner import Runner


class TestE2E(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        self.snippet = """
            provider "aws" {
              region = "eu-west-2"
              profile = "foo"
              skip_credentials_validation = true
              skip_get_ec2_platforms = true
            }

            module "root_modules" {
              source = "./mymodule"
              providers = {aws = "aws"}

              acp_prod_ingress_cidr             = "10.5.0.0/16"
              dq_ops_ingress_cidr               = "10.2.0.0/16"
              dq_internal_dashboard_subnet_cidr = "10.1.12.0/24"
              peering_cidr_block                = "1.1.1.0/24"
              apps_vpc_id                       = "vpc-12345"
              naming_suffix                     = "apps-preprod-dq"
              s3_archive_bucket                 = "bucket-name"
              s3_archive_bucket_key             = "1234567890"
              s3_archive_bucket_name            = "bucket-name"
              haproxy_private_ip                = "1.2.3.4"
              environment                       = "prod"
            }

        """
        self.result = Runner(self.snippet).result


    def test_subnet_vpc(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.subnet"]["vpc_id"], "vpc-12345")

    def test_subnet_cidr(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.subnet"]["cidr_block"], "10.1.12.0/24")

    @unittest.skip
    def test_security_group_egress(self):
        self.assertTrue(Runner.finder(self.result["root_modules"]["aws_security_group.sgrp"], egress, {
            'from_port': '0',
            'to_port': '0',
            'Protocol': '-1',
            'Cidr_blocks': '0.0.0.0/0'
        }))

    def test_subnet_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.subnet"]["tags.Name"], "subnet-internal-tableau-apps-preprod-dq")

    def test_security_group_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_security_group.sgrp"]["tags.Name"], "sg-internal-tableau-apps-preprod-dq")

    def test_db_subnet_group_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_db_subnet_group.rds"]["tags.Name"], "rds-subnet-group-internal-tableau-apps-preprod-dq")

    def test_aws_subnet_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.internal_tableau_az2"]["tags.Name"], "az2-subnet-internal-tableau-apps-preprod-dq")

    def test_db_security_group_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_security_group.internal_tableau_db"]["tags.Name"], "sg-db-internal-tableau-apps-preprod-dq")

    def test_rds_change_switch(self):
        self.assertEqual(self.result["root_modules"]["aws_db_instance.postgres"]["apply_immediately"], "true")

    def test_rds_disk_size(self):
        self.assertEqual(self.result["root_modules"]["aws_db_instance.postgres"]["allocated_storage"], "900")    

    def test_rds_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_db_instance.postgres"]["tags.Name"], "rds-postgres-internal-tableau-apps-preprod-dq")

    def test_ssm_rds_service_username(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_service_username"]["name"], "rds_internal_tableau_service_username")

    def test_ssm_rds_service_username_string_type(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_service_username"]["type"], "SecureString")

    def test_ssm_rds_service_password(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_service_password"]["name"], "rds_internal_tableau_service_password")

    def test_ssm_rds_service_password_string_type(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_service_password"]["type"], "SecureString")

    def test_ssm_rds_username(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_username"]["name"], "rds_internal_tableau_username")

    def test_ssm_rds_username_string_type(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_username"]["type"], "SecureString")

    def test_ssm_rds_password(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_password"]["name"], "rds_internal_tableau_password")

    def test_ssm_rds_password_string_type(self):
        self.assertEqual(self.result["root_modules"]["aws_ssm_parameter.rds_internal_tableau_password"]["type"], "SecureString")

if __name__ == '__main__':
    unittest.main()
