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

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role_binding.automation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_namespace.automation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.automation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.automation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [kubernetes_secret.automation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Cluster details to configure the kubeconfig file | <pre>object({<br/>    name                   = string<br/>    host                   = string<br/>    cluster_ca_certificate = string<br/>    token                  = string<br/>  })</pre> | n/a | yes |
| <a name="input_cluster_role"></a> [cluster\_role](#input\_cluster\_role) | The name of the cluster role to bind to the service account | `string` | `"cluster-admin"` | no |
| <a name="input_create_cluster_role_binding"></a> [create\_cluster\_role\_binding](#input\_create\_cluster\_role\_binding) | Create the cluster role binding | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace | `bool` | `false` | no |
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | Create the service account | `bool` | `true` | no |
| <a name="input_kubeconfig_file"></a> [kubeconfig\_file](#input\_kubeconfig\_file) | The file path to write the kubeconfig file to | `string` | `"kubeconfig.yaml"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace to deploy the educates components to | `string` | `"kube-system"` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | The name of the service account to create | `string` | `"automation"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_token-sa-kubeconfig"></a> [token-sa-kubeconfig](#output\_token-sa-kubeconfig) | Information about the generated service account for token authentication and the kubeconfig file |
