output "gke" {
  value = module.gke_for_educates.gke
}

output "kubernetes" {
  value = {
    host = nonsensitive(module.gke_for_educates.kubernetes.host)
    kubeconfig_file = module.gke_for_educates.kubeconfig_file
  }
}

output "educates" {
  value = module.educates.educates
}

output "token-sa-kubeconfig" {
  value = module.token-sa-kubeconfig
}
