# Commons
variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

# SonarQube module
variable "sonar_port" {
  description = "The port on which SonarQube will run"
  type        = number
  default     = 9000
}
