provider "google" {
  # project = var.project_id
  # region  = var.region
}

module "gke_for_educates" {
  source = "../../infrastructure/gke-for-educates"
  # source = "github.com/educates/educates-terraform-modules.git//infrastructure/gke-for-educates?ref=develop"

  project_id         = var.project_id
  region             = var.region
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  node_groups        = var.node_groups
  kubeconfig_file    = var.kubeconfig_file
}

##
# Configure the kubectl provider with all the details from the GKE cluster. We don't use
# the kubeconfig file as on deletion, the file might no longer exist.
##
provider "kubectl" {
  host                   = module.gke_for_educates.kubernetes.host
  cluster_ca_certificate = module.gke_for_educates.kubernetes.cluster_ca_certificate
  token                  = module.gke_for_educates.kubernetes.token
  load_config_file       = false
  #  config_context         = module.eks_for_educates.kubernetes.config_context
}

module "educates" {
  count = var.deploy_educates ? 1 : 0

  source = "../../platform/educates"
  # source           = "github.com/educates/educates-terraform-modules.git//platform/educates?ref=develop"
  wildcard_domain = "${var.cluster_name}.${var.TLD}"
  educates_config = {
    version = var.educates_version
  }
  infrastructure_provider = "gcp"
  gcp_config = {
    cluster_name = var.cluster_name
    project      = var.project_id
    dns_zone     = var.TLD
  }
}

module "token-sa-kubeconfig" {
  source = "../../infrastructure/token-sa-kubeconfig"
  # source = "github.com/educates/educates-terraform-modules.git//infrastructure/token-sa-kubeconfig?ref=develop"

  cluster = {
    name                   = var.cluster_name
    host                   = module.gke_for_educates.kubernetes.host
    cluster_ca_certificate = module.gke_for_educates.kubernetes.cluster_ca_certificate
    token                  = module.gke_for_educates.kubernetes.token
  }
  kubeconfig_file = "${path.root}/kubeconfig-${var.cluster_name}-token.yaml"
}
