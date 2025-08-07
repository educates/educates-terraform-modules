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
      version = "~> 2.38"
    }    

    local = {
      source = "hashicorp/local"
      version = "~> 2.5"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"
    }

  }  
  required_version = ">= 1.5.0"
}