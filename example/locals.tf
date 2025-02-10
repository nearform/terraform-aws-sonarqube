locals {
  common_tags = {
    Project     = "sonarqube"
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
  }
}
