# Creation of a Service account with a secret token for permanent kubeconfig access

This module will create a secret in the provided cluster (defined by the `cluster` variable) using a permanent token for a given service account in a given namespace.

## Features

- It can create the namespace `namespace` for the service account via `create_namespace`
- It can create the service account `service_account_name` via `create_service_account`
- It can create a Cluster Role Binding for the SA to a Cluster Role `cluster_role` via `create_cluster_role_binding`
- It will create a kubeconfig file with name defined by `kubeconfig_file`

## Configuration
You can see the possible configuration in [variables.tf](variables.tf), but most of the times, the one you will need to use is `cluster`

The `cluster` variable will have:
- name: Name of the cluster (this will be used in the generated kubeconfig)
- host: Cluster's host (as returned by gke or eks modules)
- cluster_ca_certificate: Cluster's CA certificate (as returned by gke or eks modules)
- token: Cluster's access token string (as returned by gke or eks modules)

### Example usage
This is how you could use this module. Typically the values to use will come from previous modules used in your root module.

```
module "token-sa-kubeconfig" {
  source = "github.com/educates/educates-terraform-modules.git//infrastructure/token-sa-kubeconfig?ref=main"

  cluster = {
    name                   = var.cluster_name
    host                   = module.gke_for_educates.kubernetes.host
    cluster_ca_certificate = module.gke_for_educates.kubernetes.cluster_ca_certificate
    token                  = module.gke_for_educates.kubernetes.token
  }
  kubeconfig_file = "${path.root}/kubeconfig-${var.cluster_name}-token.yaml"
}
```

__NOTE__: Replace module version with the appropriate one.