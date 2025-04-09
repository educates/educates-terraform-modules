output "gke" {
  value = {
    cluster_name                = var.cluster_name #module.eks.cluster_name
    network_uri                 = module.vpc.network_self_link
    node_pools                  = local.node_pools
    kubernetes_version          = data.google_container_engine_versions.gke_versions.latest_master_version
    service_account             = google_service_account.default.email
    certmanager_service_account = google_service_account.cert-manager-gsa.email
    externaldns_service_account = google_service_account.external-dns-gsa.email
  }

  #   depends_on = [module.vpc, module.eks, module.certmanager_irsa_role, module.externaldns_irsa_role]
}

output "kubeconfig_file" {
  value       = local.kubeconfig_filename
  description = "kubeconfig full path for the AWS EKS cluster"
}

# # Some inspiration from: https://github.com/TykTechnologies/tyk-performance-testing/blob/main/modules/clouds/aws/main.tf
output "kubernetes" {
  value = {
    host                   = "https://${module.gke.endpoint}"
    username               = null
    password               = null
    token                  = data.google_client_config.default.access_token
    client_key             = null
    client_certificate     = null
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    config_path            = null
    config_context         = null
    kubeconfig_raw         = local.kubeconfig
  }

  # depends_on = [module.gke]
}
