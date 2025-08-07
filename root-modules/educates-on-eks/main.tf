# default AWS provider
provider "aws" {
  region  = var.aws_region
  # profile = var.profile  # If we need multiple profiles, create a variable profile
}

##
# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration
##
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

module "eks_for_educates" {
  source = "../../infrastructure/eks-for-educates"
  # source = "github.com/educates/educates-terraform-modules.git//infrastructure/eks-for-educates"
  # version = "~> 1.0"

  # We use terraform data sources to get the account_id
  aws_account_id     = data.aws_caller_identity.current.account_id
  aws_region         = var.aws_region
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  node_groups        = var.node_groups
  ami_type           = var.ami_type
  manage_aws_auth_configmap = var.manage_aws_auth_configmap
  aws_auth_users            = var.aws_auth_users
  aws_auth_roles            = var.aws_auth_roles

  kms_key_administrators = var.kms_key_administrators
}

##
# Configure the kubectl provider with all the details from the EKS cluster. We don't use
# the kubeconfig file as on deletion, the file might no longer exist.
##
provider "kubectl" {
  host                   = module.eks_for_educates.kubernetes.host
  cluster_ca_certificate = module.eks_for_educates.kubernetes.cluster_ca_certificate
  token                  = module.eks_for_educates.kubernetes.token
  load_config_file       = false
  #  config_context         = module.eks_for_educates.kubernetes.config_context
}

module "educates" {
  count = var.deploy_educates ? 1 : 0

  source = "../../platform/educates"
  # source           = "github.com/educates/educates-terraform-modules.git//platform/educates"
  # version = "~> 1.0"
  wildcard_domain = "${var.cluster_name}.${var.TLD}"
  educates_config = {
    version = var.educates_version
  }
  infrastructure_provider = "aws"
  aws_config = {
    account_id   = data.aws_caller_identity.current.account_id
    cluster_name = var.cluster_name
    region       = var.aws_region
    dns_zone     = var.TLD
  }
}

module "token-sa-kubeconfig" {
  source = "../../infrastructure/token-sa-kubeconfig"
  # source = "github.com/educates/educates-terraform-modules.git//infrastructure/token-sa-kubeconfig"
  # version = "~> 1.0"

  cluster = {
    name                   = var.cluster_name
    host                   = module.eks_for_educates.kubernetes.host
    cluster_ca_certificate = module.eks_for_educates.kubernetes.cluster_ca_certificate
    token                  = module.eks_for_educates.kubernetes.token
  }
  kubeconfig_file = "${path.root}/kubeconfig-${var.cluster_name}-token.yaml"
}

