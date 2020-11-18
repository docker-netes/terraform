provider "aws" {
  region = "us-east-2"
}
# VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_blocks
  enable_dns_hostnames = true
  tags = {
    Name = "rds_vpc"
  }
}
# Subenets in rds_vpc
/*resource "aws_subnet" "subnets" {
  count                   = length(var.vpc_subnet_ids)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.vpc_subnet_ids, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "rds_vpc_subnet_${count.index + 1}"
  }
}

resource "aws_db_subnet_group" "default_rds_mssql" {
  name        = "${var.environment}-rds-mssql-subnet-group"
  description = "The ${var.environment} rds-mssql private subnet group."
  count = length(aws_subnet.subnets)
  subnet_ids  = element(aws_subnet.subnets)
}*/

resource "aws_subnet" "subnet1" {
  //count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.vpc_subnet_id1
  availability_zone       = var.availability_zones1
  //availability_zone       = element(var.availability_zones, count.index)
tags = {
    Name = "rds_vpc_subnet1"
  }
}
resource "aws_subnet" "subnet2" {
  //count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.vpc_subnet_id2
  availability_zone       = var.availability_zones2
  //availability_zone       = element(var.availability_zones, count.index)
tags = {
    Name = "rds_vpc_subnet2"
  }
}

resource "aws_db_subnet_group" "default_rds_mssql" {
  name        = "${var.environment}-rds-mssql-subnet-group"
  description = "The ${var.environment} rds-mssql private subnet group."
  subnet_ids  = ["${aws_subnet.subnet1.id}", "${aws_subnet.subnet2.id}"]
tags = {
    Name = "rds_vpc_subnetgroup"
  }
}

resource "aws_security_group" "rds_mssql_security_group" {
  name        = "${var.environment}-all-rds-mssql-internal"
  description = "${var.environment} allow all vpc traffic to rds mssql."
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_blocks}"]
  }

}

resource "aws_security_group" "rds_mssql_security_group_vpn" {
  name        = "${var.environment}-all-rds-mssql-vpn"
  description = "Allow all inbound traffic from vpn to rds mssql."
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_blocks_vpn}"]
  }
}

resource "aws_s3_bucket" "rdsbucket" {
   bucket = "rdsbucketnew"
   acl = "private"
   versioning {
      enabled = true
   }
}

resource "aws_db_parameter_group" "rdspgroup" {
  name   = "rds-pg"
  family = "sqlserver-ex-14.0"
}

resource "aws_iam_role" "rdsback_role" {
  name = "rdsback_role"
  path = "/service-role/"

  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "rds.amazonaws.com"
          },
           "Effect": "Allow",
           "Sid": ""
        }
      ]
    }
EOF
  tags = {
    tag-key = "tag-value"
  }
  provisioner "local-exec" {
    # I wouldn't go for less than 10. I tried saving a few seconds and failed. :/
    command = "sleep 10"
  }
}

resource "aws_iam_role_policy_attachment" "rdsrole-attach" {
  role       = aws_iam_role.rdsback_role.name
  policy_arn = "arn:aws:iam::724932421193:policy/service-role/sqlNativeBackup-2020-11-06-05.13.51.161"
}

resource "aws_db_option_group" "rdsoptiongrp" {
  name                     = "option-group-rdsmssql"
  option_group_description = "rds Option Group"
  engine_name              = "sqlserver-ex"
  major_engine_version     = "14.00"


  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = "${aws_iam_role.rdsback_role.arn}"
    }
  }
  depends_on = ["aws_iam_role.rdsback_role"]
}

resource "aws_db_instance" "rds_mssql" {
  depends_on                = ["aws_db_subnet_group.default_rds_mssql"]
  identifier                = "${var.environment}-mssql"
  allocated_storage         = "${var.rds_allocated_storage}"
  license_model             = "license-included"
  storage_type              = "gp2"
  engine                    = "sqlserver-ex"
  engine_version            = "14.00.3294.2.v1"
  instance_class            = "${var.rds_instance_class}"
  multi_az                  = "${var.rds_multi_az}"
  username                  = "${var.mssql_admin_username}"
  password                  = "${var.mssql_admin_password}"
  vpc_security_group_ids    = ["${aws_security_group.rds_mssql_security_group.id}", "${aws_security_group.rds_mssql_security_group_vpn.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.default_rds_mssql.id}"
  parameter_group_name      = "${aws_db_parameter_group.rdspgroup.name}"
  option_group_name         = "${aws_db_option_group.rdsoptiongrp.name}"
  backup_retention_period   = 0
  skip_final_snapshot       = "${var.skip_final_snapshot}"
  final_snapshot_identifier = "${var.environment}-mssql-final-snapshot"
}

// Identifier of the mssql DB instance.
output "mssql_id" {
  value = "${aws_db_instance.rds_mssql.id}"
}

// Address of the mssql DB instance.
output "mssql_address" {
  value = "${aws_db_instance.rds_mssql.address}"
}
