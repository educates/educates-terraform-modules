terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }  
  required_version = ">= 1.5.0"
}