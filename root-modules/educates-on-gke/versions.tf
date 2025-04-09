terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
    }
  }  
  required_version = ">= 1.11.0"
}