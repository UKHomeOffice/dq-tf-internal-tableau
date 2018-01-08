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

              acp_prod_ingress_cidr        = "10.5.0.0/16"
              dq_ops_ingress_cidr          = "10.2.0.0/16"
              dq_internal_dashboard_subnet_cidr                 = "10.1.12.0/24"
              peering_cidr_block           = "1.1.1.0/24"
              greenplum_ip                 = "foo"
              apps_vpc_id                  = "foo"
              naming_suffix                = "apps-preprod-dq"
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
        self.assertEqual(self.result["root_modules"]["aws_subnet.subnet"]["vpc_id"], "foo")

    def test_subnet_cidr(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.subnet"]["cidr_block"], "10.1.12.0/24")

    @unittest.skip
    def test_security_group_ingress(self):
        self.assertTrue(Runner.finder(self.result["root_modules"]["aws_security_group.sgrp"], ingress, {
            'from_port': '443',
            'to_port': '443',
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

if __name__ == '__main__':
    unittest.main()
