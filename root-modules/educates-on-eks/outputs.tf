output "eks" {
  value = module.eks_for_educates
  sensitive = true
}

output "kubernetes" {
  value = {
    host = nonsensitive(module.eks_for_educates.kubernetes.host)
    kubeconfig_file = module.eks_for_educates.kubeconfig_file
  }
}

output "educates" {
  value = module.educates.educates
}

output "token-sa-kubeconfig" {
  value = module.token-sa-kubeconfig
}