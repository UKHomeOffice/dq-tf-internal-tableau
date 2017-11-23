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
            }
            
        """
        self.result = Runner(self.snippet).result

    def test_instance_ami(self):
        self.assertEqual(self.result["root_modules"]["aws_instance.internal_tableau"]["ami"], "foo")

    def test_instance_type(self):
        self.assertEqual(self.result["root_modules"]["aws_instance.Internal_Tableau"]["instance_type"], "foo")


if __name__ == '__main__':
    unittest.main()