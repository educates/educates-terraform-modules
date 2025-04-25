terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
    }
  }  
  required_version = ">= 1.5.0"
}