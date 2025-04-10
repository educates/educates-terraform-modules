variable "cluster" {
  description = "Cluster details to configure the kubeconfig file"
  type = object({
    name                   = string
    host                   = string
    cluster_ca_certificate = string
    token                  = string
  })
}

variable "service_account_name" {
  description = "The name of the service account to create"
  default     = "automation"
}

variable "namespace" {
  description = "The namespace to deploy the educates components to"
  default     = "kube-system"
}

variable "cluster_role" {
  description = "The name of the cluster role to bind to the service account"
  default     = "cluster-admin"
}

variable "create_namespace" {
  description = "Create the namespace"
  default     = false
}

variable "create_service_account" {
  description = "Create the service account"
  default     = true
}

variable "create_cluster_role_binding" {
  description = "Create the cluster role binding"
  default     = true
}

variable "kubeconfig_file" {
  description = "The file path to write the kubeconfig file to"
  default     = "kubeconfig.yaml"
}
