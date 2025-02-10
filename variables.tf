# Commons
variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = "sonarqube"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Networking
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "database_subnets" {
  description = "List of IDs of database subnets"
  type        = list(string)
}

variable "database_subnet_group_name" {
  description = "Name of database subnet group"
  type        = string
}

variable "private_subnets" {
  description = "List of IDs of private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of IDs of public subnets"
  type        = list(string)
}

# SonarQube
variable "sonar_db_server" {
  description = "The name of the SonarQube database server"
  type        = string
  default     = "sonardbserver"
}

variable "sonar_db_instance_class" {
  description = "The name of the SonarQube database server instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "sonar_db_storage_type" {
  description = "The name of the SonarQube database server storage type"
  type        = string
  default     = "gp2"
}

variable "sonar_db_name" {
  description = "The name of the SonarQube database"
  type        = string
  default     = "sonar"
}

variable "sonar_db_user" {
  description = "The username for the SonarQube database"
  type        = string
  default     = "sonar"
}

variable "sonar_port" {
  description = "The port on which SonarQube will run"
  type        = number
  default     = 9000
}

variable "sonar_container_name" {
  description = "The name of the SonarQube container"
  type        = string
  default     = "sonarqube"
}
