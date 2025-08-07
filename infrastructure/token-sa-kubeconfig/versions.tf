terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.5"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}