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
            }

        """
        self.result = Runner(self.snippet).result


    @unittest.skip
    def test_instance_ami(self):
        self.assertEqual(self.result["root_modules"]["aws_instance.instance"]["ami"], "foo")

    @unittest.skip  # @TODO
    def test_instance_user_data(self):
        greenplum_listen = hashlib.sha224("LISTEN_HTTP=0.0.0.0:443 CHECK_GP=foo:5432").sha1()
        self.assertEqual(self.result["root_modules"]["aws_instance.instance"]["user_data"], greenplum_listen)

    def test_subnet_vpc(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.subnet"]["vpc_id"], "vpc-12345")

    def test_subnet_cidr(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.subnet"]["cidr_block"], "10.1.12.0/24")

    @unittest.skip
    def test_security_group_ingress(self):
        self.assertTrue(Runner.finder(self.result["root_modules"]["aws_security_group.sgrp"], ingress, {
            'from_port': '80',
            'to_port': '80',
            'from_port': '3389',
            'to_port': '3389',
            'Protocol': 'tcp',
            'Cidr_blocks': '0.0.0.0/0'
        }))
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

    def test_ec2_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_instance.int_tableau"]["tags.Name"], "ec2-internal-tableau-apps-preprod-dq")

    def test_ec2_blue_tags(self):
        self.assertEqual(self.result["root_modules"]["aws_instance.int_tableau_blue"]["tags.Name"], "ec2-internal-tableau-v2018-03-apps-preprod-dq")

if __name__ == '__main__':
    unittest.main()
