module "gke_auth" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "36.2.0"

  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}


provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = module.gke.name
    clusters = [{
      name = module.gke.name
      cluster = {
        certificate-authority-data = module.gke.ca_certificate
        server                     = "https://${module.gke.endpoint}"
      }
    }]
    contexts = [{
      name = module.gke.name
      context = {
        cluster = module.gke.name
        user    = module.gke.name
      }
    }]
    users = [{
      name = module.gke.name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "gke-gcloud-auth-plugin"
          # args = []
          installHint = "Install gke-gcloud-auth-plugin for use with kubectl by following\nhttps://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin"
          # provideClusterInfo = true
          interactiveMode = "IfAvailable"
        }
      }
    }]
  })

  # Only if var.kubeconfig_file is not set
  # kubeconfig_file = var.kubeconfig_file
  kubeconfig_filename = var.kubeconfig_file == "" ? "${path.root}/kubeconfig-${var.cluster_name}.yaml" : var.kubeconfig_file
}

resource "local_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = local.kubeconfig_filename

  depends_on = [
    module.gke, module.gke_auth
  ]
}