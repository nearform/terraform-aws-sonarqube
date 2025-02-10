provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source                                 = "terraform-aws-modules/vpc/aws"
  version                                = "5.18.1"
  name                                   = "sonarqubevpc"
  cidr                                   = "10.101.0.0/16"
  azs                                    = ["eu-west-1a", "eu-west-1b"]
  database_subnets                       = ["10.101.21.0/24", "10.101.22.0/24"]
  private_subnets                        = ["10.101.1.0/24", "10.101.2.0/24"]
  public_subnets                         = ["10.101.101.0/24", "10.101.102.0/24"]
  create_private_nat_gateway_route       = true
  enable_nat_gateway                     = true
  single_nat_gateway                     = true
  one_nat_gateway_per_az                 = false
  enable_dns_hostnames                   = true
  enable_dns_support                     = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = false
  database_subnet_group_name             = "sonarqubedbsubnetgroup"
  tags = {
    Project     = "sonarqube"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

module "sonarqube" {
  source                     = "../"
  vpc_id                     = module.vpc.vpc_id
  database_subnets           = module.vpc.database_subnets
  private_subnets            = module.vpc.private_subnets
  public_subnets             = module.vpc.public_subnets
  database_subnet_group_name = module.vpc.database_subnet_group_name
}
