// Environment name, used as prefix to name resources.
variable "environment" {
  default = "dev"
}

// The allocated storage in gigabytes.
variable "rds_allocated_storage" {
  default = "250"
}

// The instance type of the RDS instance.
variable "rds_instance_class" {
  default = "db.t3.medium"
}

// Specifies if the RDS instance is multi-AZ.
variable "rds_multi_az" {
  default = "false"
}

// Username for the administrator DB user.
variable "mssql_admin_username" {
  default = "admin"
}

// Password for the administrator DB user.
variable "mssql_admin_password" {
  default = "admin123"
}

// A list of VPC subnet identifiers.
variable "vpc_subnet_id1" {
  default ="172.0.1.0/25"
}

variable "vpc_subnet_id2" {
  default ="172.0.1.128/25"
}

/*variable "availability_zones" {
  type = list(string)
  default = ["us-east-2a", "us-east-2b"]
}*/
variable "availability_zones1" {
  default = "us-east-2a"
}
variable "availability_zones2" {
  default = "us-east-2b"
}

// List of CIDR blocks that will be granted to access to mssql instance.
variable "vpc_cidr_blocks" {
  default = "172.0.0.0/16"
}

// Additional list of CIDR blocks that will be granted to access to mssql instance.
// These list is meant to be used in the vpn security group.
variable "vpc_cidr_blocks_vpn" {
  default = "172.0.1.0/24"
}

// Determines whether a final DB snapshot is created before the DB instance is deleted.
variable "skip_final_snapshot" {
  type = string
  default = "false"
}
