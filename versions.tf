terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}