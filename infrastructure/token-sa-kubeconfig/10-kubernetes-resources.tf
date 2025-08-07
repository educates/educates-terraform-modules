resource "kubernetes_namespace" "automation" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account" "automation" {
  # Create optionally a service account for the automation
  count = var.create_service_account ? 1 : 0
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
  }

  depends_on = [ 
    kubernetes_namespace.automation 
  ]
}

resource "kubernetes_cluster_role_binding" "automation" {
  count = var.create_cluster_role_binding ? 1 : 0
  metadata {
    name = var.service_account_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.cluster_role
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.service_account_name
    namespace = var.namespace
  }

  depends_on = [ 
    kubernetes_service_account.automation 
  ]
}

resource "kubernetes_secret" "automation" {
  metadata {
    name = var.service_account_name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = var.service_account_name
    }
  }
  type = "kubernetes.io/service-account-token"
  data = {}
  wait_for_service_account_token = true
  
  lifecycle { 
    ignore_changes = [data]
  }

  depends_on = [ 
    kubernetes_cluster_role_binding.automation
  ]
}

data "kubernetes_secret" "automation" {
  metadata {
    name      = kubernetes_secret.automation.metadata[0].name
    namespace = kubernetes_secret.automation.metadata[0].namespace
  }
}