terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # "5.94.1"
    }
    kubectl = {
      source  = "alekc/kubectl"
    }
  }  
  required_version = ">= 1.11.0"

  ##
  # UNCOMMENT THE BACKEND BLOCK TO USE S3 STATE
  ##  
  # backend "s3" {
  #   bucket               = "educates-tf"
  #   key                  = "terraform.tfstate"
  #   workspace_key_prefix = "state/educates/workspaces"
  #   region               = "eu-west-1"
  #   # profile              = "strigo-infra" # If we need multiple profiles, create a variable profile
  #   encrypt              = true
  # }
}