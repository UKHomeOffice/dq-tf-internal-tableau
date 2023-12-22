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
            }
            module "root_modules" {
              source = "./mymodule"
              providers = {aws = aws}
              acp_prod_ingress_cidr             = "10.5.0.0/16"
              dq_ops_ingress_cidr               = "10.2.0.0/16"
              dq_internal_dashboard_subnet_cidr = "10.1.12.0/24"
              peering_cidr_block                = "1.1.1.0/24"
              apps_vpc_id                       = "vpc-12345"
              naming_suffix                     = "apps-preprod-dq"
              s3_archive_bucket                 = "bucket-name"
              s3_archive_bucket_key             = "1234567890"
              s3_archive_bucket_name            = "bucket-name"
              s3_httpd_config_bucket            = "s3-bucket-name"
              s3_httpd_config_bucket_key        = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
              haproxy_private_ip                = "1.2.3.4"
              haproxy_private_ip2               = "1.2.3.5"
              environment                       = "prod"
              security_group_ids                = "sg-1234567890"
              lambda_subnet                     = "subnet-1234567890"
              lambda_subnet_az2                 = "subnet-1234567890"
              rds_enhanced_monitoring_role      = "arn:aws:iam::123456789:role/rds-enhanced-monitoring-role"
            }
        """
        self.runner = Runner(self.snippet)
        self.result = self.runner.result

    def test_subnet_vpc(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_subnet.subnet", "vpc_id"), "vpc-12345")

    def test_subnet_cidr(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_subnet.subnet", "cidr_block"), "10.1.12.0/24")

    @unittest.skip
    def test_security_group_egress(self):
        self.assertTrue(Runner.finder(self.result["root_modules"]["aws_security_group.sgrp"], egress, {
            'from_port': '0',
            'to_port': '0',
            'Protocol': '-1',
            'Cidr_blocks': '0.0.0.0/0'
        }))

    def test_subnet_tags(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_subnet.subnet", "tags"), {"Name": "subnet-internal-tableau-apps-preprod-dq"})

    def test_security_group_tags(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_security_group.sgrp", "tags"), {"Name": "sg-internal-tableau-apps-preprod-dq"})

    def test_db_subnet_group_tags(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_db_subnet_group.rds", "tags"), {"Name": "rds-subnet-group-internal-tableau-apps-preprod-dq"})

    def test_aws_subnet_tags(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_subnet.internal_tableau_az2", "tags"), {"Name": "az2-subnet-internal-tableau-apps-preprod-dq"})

    def test_db_security_group_tags(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_security_group.internal_tableau_db", "tags"), {"Name": "sg-db-internal-tableau-apps-preprod-dq"})

    def test_rds_change_switch(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.postgres", "apply_immediately"), False)

    def test_rds_disk_size(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.postgres", "allocated_storage"), 3630)

    def test_rds_deletion_protection(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.postgres", "deletion_protection"), True)

    def test_rds_tags(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.postgres", "tags"), {"Name": "rds-postgres-internal-tableau-apps-preprod-dq"})

    def test_ssm_rds_service_username(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_service_username", "name"), "rds_internal_tableau_service_username")

    def test_ssm_rds_service_username_string_type(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_service_username", "type"), "SecureString")

    def test_ssm_rds_service_password(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_service_password", "name"), "rds_internal_tableau_service_password")

    def test_ssm_rds_service_password_string_type(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_service_password", "type"), "SecureString")

    def test_ssm_rds_username(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_username", "name"), "rds_internal_tableau_username")

    def test_ssm_rds_username_string_type(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_username", "type"), "SecureString")

    def test_ssm_rds_password(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_password", "name"), "rds_internal_tableau_password")

    def test_ssm_rds_password_string_type(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_ssm_parameter.rds_internal_tableau_password", "type"), "SecureString")

    def test_iam_role(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_iam_role.postgres", "name"), "rds-postgres-role-internal-tableau-apps-preprod-dq")

    # def test_staging_instance_tag(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_instance.int_tableau_linux_staging[0]", "tags"), {"Name": "ec2-staging-internal-tableau-apps-preprod-dq"})
    #
    # def test_rds_staging_tags(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.internal_reporting_snapshot_stg[0]", "tags"), {"Name": "stg-postgres-internal-tableau-apps-preprod-dq"})
    #
    # def test_rds_staging_tags(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.internal_reporting_snapshot_stg[0]", "tags"), {"Name": "stg-postgres-internal-tableau-apps-preprod-dq"})

    def test_rds_postgres_backup_window(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.postgres", "backup_window"), "00:00-01:00")

    # def test_rds_postgres_stg_backup_window(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.internal_reporting_snapshot_stg[0]", "backup_window"), "00:00-01:00")
    #
    # def test_rds_postgres_maintenance_window(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.postgres", "maintenance_window"), "mon:01:00-mon:02:00")
    #
    # def test_rds_postgres_stg_maintenance_window(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.internal_reporting_snapshot_stg[0]", "maintenance_window"), "tue:01:00-tue:02:00")
    #
    # def test_rds_postgres_stg_engine_version(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.internal_reporting_snapshot_stg[0]", "engine_version"), "10.10")
    #
    # def test_rds_postgres_stg_apply_immediately(self):
    #     self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.internal_reporting_snapshot_stg[0]", "apply_immediately"), True)

    def test_rds_postgres_postgres_engine_version(self):
        self.assertEqual(self.runner.get_value("module.root_modules.aws_db_instance.postgres", "engine_version"), "14.7")


if __name__ == '__main__':
    unittest.main()
