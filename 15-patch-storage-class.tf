resource "kubernetes_annotations" "default-storageclass" {
 api_version = "storage.k8s.io/v1"
 kind        = "StorageClass"
 force       = "true"
  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "true"
  }

  depends_on = [module.eks]
}
