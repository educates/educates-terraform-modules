output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.cluster_name
}

output "eks" {
  value = {
    cluster_name     = module.eks.cluster_name
    cluster_version  = module.eks.cluster_version
    region           = var.aws_region
    cluster_endpoint = module.eks.cluster_endpoint
    vpc_id           = module.vpc.vpc_id
    # This is a list of objects. We don't want all the information here
    # node_groups                = module.eks.eks_managed_node_groups
    # This is a list of objects. We don't want all the information here
    # cluster_addons             = module.eks.cluster_addons 
    # This is a list of objects. We don't want all the information here
    # cluster_identity_providers = module.eks.cluster_identity_providers
    certmanager_irsa_role = module.certmanager_irsa_role.iam_role_arn
    externaldns_irsa_role = module.externaldns_irsa_role.iam_role_arn
  }

  depends_on = [module.vpc, module.eks, module.certmanager_irsa_role, module.externaldns_irsa_role]
}

output "kubeconfig_file" {
  value       = var.kubeconfig_file
  description = "kubeconfig full path for the AWS EKS cluster"
}

# Some inspiration from: https://github.com/TykTechnologies/tyk-performance-testing/blob/main/modules/clouds/aws/main.tf
output "kubernetes" {
  value = {
    host                   = module.eks.cluster_endpoint
    username               = null
    password               = null
    token                  = data.aws_eks_cluster_auth.this.token
    client_key             = null
    client_certificate     = null
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    config_path            = try(local_file.kubeconfig[0].filename, null)
  }
}