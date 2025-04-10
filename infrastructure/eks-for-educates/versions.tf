terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.22.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
       version = "2.36.0"
    }
  }
}