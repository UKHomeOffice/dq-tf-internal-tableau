# pylint: disable=missing-docstring, line-too-long, protected-access
import unittest
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
              
              tableau_internal_ami_id = "foo"
              tableau_internal_instance_type = "foo"
  
              protocol = "foo"
              security_cidr = "foo" 
              
              vpc_id = "foo"
              subnet_cidr = "foo"
                  
              
            } 
            
        """
        self.result = Runner(self.snippet).result


    # Instance
    def test_instance_ami(self):
        self.assertEqual(self.result["root_modules"]["aws_instance.internal_tableau"]["ami"], "foo")

    def test_instance_type(self):
        self.assertEqual(self.result["root_modules"]["aws_instance.internal_tableau"]["instance_type"], "foo")

    # Security group
    def test_security_group_from_port(self):
        self.assertEqual(self.result["root_modules"]["aws_security_group.internal_tableau"]["from_port"], "foo")

    def test_security_group_to_port(self):
        self.assertEqual(self.result["root_modules"]["aws_security_group.internal_tableau"]["to_port"], "foo")

    def test_security_group_protocol(self):
        self.assertEqual(self.result["root_modules"]["aws_security_group.internal_tableau"]["protocol"], "foo")

    def test_security_group_cidr_blocks(self):
        self.assertEqual(self.result["root_modules"]["aws_security_group.internal_tableau"]["cidr_blocks"], "foo")

    # Subnet
    def test_subnet_vpc(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.internal_tableau"]["vpc_id"], "foo")

    def test_subnet_cidr(self):
        self.assertEqual(self.result["root_modules"]["aws_subnet.internal_tableau"]["cidr_block"], "foo")


if __name__ == '__main__':
    unittest.main()