provider "aws" {
  region = local.region
}

module "vpc" {
  source                                 = "terraform-aws-modules/vpc/aws"
  version                                = "5.18.1"
  name                                   = "${local.name}vpc"
  azs                                    = local.vnet_azs
  cidr                                   = local.vnet_cidr
  database_subnets                       = local.database_subnets
  private_subnets                        = local.private_subnets
  public_subnets                         = local.public_subnets
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
  database_subnet_group_name             = "${local.name}db"
  tags                                   = local.common_tags
}

module "sonarqube" {
  source                     = "../"
  sonar_image_tag            = local.sonar_image_tag
  sonar_port                 = local.sonar_port
  vpc_id                     = module.vpc.vpc_id
  database_subnets           = module.vpc.database_subnets
  private_subnets            = module.vpc.private_subnets
  public_subnets             = module.vpc.public_subnets
  database_subnet_group_name = module.vpc.database_subnet_group_name
  tags                       = local.common_tags
}
