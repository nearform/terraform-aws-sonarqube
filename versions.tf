terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80, < 6.11"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 3.7"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2, < 3.3"
    }

  }
}
