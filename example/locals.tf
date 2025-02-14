locals {
  name             = "sonarqubetest"
  region           = "eu-west-1"
  vnet_azs         = ["eu-west-1a", "eu-west-1b"]
  vnet_cidr        = "10.101.0.0/16"
  database_subnets = ["10.101.21.0/24", "10.101.22.0/24"]
  private_subnets  = ["10.101.1.0/24", "10.101.2.0/24"]
  public_subnets   = ["10.101.101.0/24", "10.101.102.0/24"]
  sonar_image_tag  = "10.7.0-community"
  sonar_port       = "9000"
  common_tags = {
    Project     = "sonarqube"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
