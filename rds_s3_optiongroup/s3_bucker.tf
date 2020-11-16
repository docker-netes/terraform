provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "rdsbucket" { 
   bucket = "rdsbucketnew"
   acl = "private"
   versioning { 
      enabled = true
   } 
   tags = { 
     Name = "bucket" 
     Environment = "dev" 
   } 
}

resource "aws_db_parameter_group" "rdspgroup" {
  name   = "rds-pg"
  family = "sqlserver-ex-14.0"
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
      value = "arn:aws:iam::724932421193:role/service-role/rdsback"
    }
  }
}
