terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.47.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.7"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.38.0"
    }    
  }
}