# Commons
variable "project_name" {
  type = string
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

# VPC module
variable "vpc_id" {
  type = string
}
variable "database_subnets" {
  type        = list(string)
  description = "List of IDs of database subnets"
}
variable "database_subnet_group_name" {
  type        = string
  description = "Name of database subnet group"
}
variable "private_subnets" {
  type        = list(string)
  description = "List of IDs of private subnets"
}
variable "public_subnets" {
  type        = list(string)
  description = "List of IDs of public subnets"
}

# SonarQube module
variable "sonar_port" {
  description = "The port on which SonarQube will run"
  type        = number
  default     = 9000
}
