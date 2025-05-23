locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = module.eks.cluster_name
    clusters = [{
      name = module.eks.cluster_name
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = module.eks.cluster_name
      context = {
        cluster = module.eks.cluster_name
        user    = module.eks.cluster_name
      }
    }]
    users = [{
      name = module.eks.cluster_name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            module.eks.cluster_name,
            "--region",
            var.aws_region,
            "--output",
            "json"
          ]
        }
      }
    }]
  })
}

resource "local_file" "kubeconfig" {
  count = var.create_kubeconfig ? 1 : 0
  
  content  = local.kubeconfig
  filename = var.kubeconfig_file

  depends_on = [
    module.eks
  ]
}