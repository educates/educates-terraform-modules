locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = var.cluster.name
    clusters = [{
      name = var.cluster.name
      cluster = {
        certificate-authority-data = base64encode(var.cluster.cluster_ca_certificate)
        server                     = var.cluster.host
      }
    }]
    contexts = [{
      name = var.cluster.name
      context = {
        cluster = var.cluster.name
        user    = var.service_account_name
      }
    }]
    users = [{
      name = var.service_account_name
      user = {
        token = data.kubernetes_secret.automation.data["token"]
      }
    }]
  })
}

resource "local_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = var.kubeconfig_file
}