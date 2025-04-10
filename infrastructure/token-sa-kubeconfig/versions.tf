terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      #version = "2.31.0"
    }
    local = {
      source = "hashicorp/local"
#      version = "2.5.2"
    }
    time = {
      source = "hashicorp/time"
#      version = "0.11.2"
    }
  }
}