terraform {
  required_version = ">= 1.11.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.28.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.6"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.36.0"
    }    
  }
}