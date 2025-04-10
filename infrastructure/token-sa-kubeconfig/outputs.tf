output "token-sa-kubeconfig" {
  description = "Information about the generated service account for token authentication and the kubeconfig file"
  value = {
    service_account = var.service_account_name
    namespace       = var.namespace
    kubeconfig_file = local_file.kubeconfig.filename
  }
}
