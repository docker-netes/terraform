provider "aws" {
  region = "us-east-2"
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
