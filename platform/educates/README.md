# Terraform module to install Educates (3.x)

Terraform module for Educates 3.x. This needs to be used after creating a GKE or EKS cluster with the
corresponding Terraform modules for Educates, as they provide some pre-requisites like IAM and WorkloadIdentity.

This module will:

- Deploy kapp-controller (upstream definition)
- Create a kubernetes namespace in the cluster for Educates Carvel app (Defined by variable `educates_app.namespace`)
- Create required RBAC for the Educates Carvel App (Service Account, Cluster Role Binding)
- Create the required Educates Configuration (based of provided variables) and save the configuration in a Secret in the aforementioned namespace
- Create the Educates Carvel App properly configured. It will have an overlay so that kapp-controller, if enabled in config, is removed.

## Configure Educates

Either use provided terraform variables and by selecting the `infrastructure_provider` Educates will be configured with it's default opinions, or
you can provide a a variable `educates_config.config_file` with Educates Configuration format that will be merged with the default module configuration
(overriding those values that overlap), or will replace the complete configuration if `educates_config.config_is_to_be_merged` is `False`.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 2.1.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 2.1.3 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_deepmerge_aws_config"></a> [deepmerge\_aws\_config](#module\_deepmerge\_aws\_config) | Invicton-Labs/deepmerge/null | 0.1.6 |
| <a name="module_deepmerge_educates_app_config"></a> [deepmerge\_educates\_app\_config](#module\_deepmerge\_educates\_app\_config) | Invicton-Labs/deepmerge/null | 0.1.6 |
| <a name="module_deepmerge_gcp_config"></a> [deepmerge\_gcp\_config](#module\_deepmerge\_gcp\_config) | Invicton-Labs/deepmerge/null | 0.1.6 |

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.clusterrolebinding_app_installs](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/resources/manifest) | resource |
| [kubectl_manifest.educates_app](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/resources/manifest) | resource |
| [kubectl_manifest.educates_app_secret](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/resources/manifest) | resource |
| [kubectl_manifest.kapp_controller](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/resources/manifest) | resource |
| [kubectl_manifest.namespace_app_installs](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/resources/manifest) | resource |
| [kubectl_manifest.serviceaccount_app_installs](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/resources/manifest) | resource |
| [time_sleep.k8s_app_rbac](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_kapp_controller](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [kubectl_file_documents.docs](https://registry.terraform.io/providers/alekc/kubectl/2.1.3/docs/data-sources/file_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_config"></a> [aws\_config](#input\_aws\_config) | TODO: Make these into a struct #### AWS #### | <pre>object({<br/>    account_id   = string<br/>    cluster_name = string<br/>    region       = string<br/>    dns_zone     = string<br/>  })</pre> | <pre>{<br/>  "account_id": "",<br/>  "cluster_name": "",<br/>  "dns_zone": "",<br/>  "region": ""<br/>}</pre> | no |
| <a name="input_educates_app"></a> [educates\_app](#input\_educates\_app) | n/a | <pre>object({<br/>    namespace   = optional(string, "package-installs")<br/>    sync_period = optional(string, "8760h0m0s")<br/>  })</pre> | `{}` | no |
| <a name="input_educates_config"></a> [educates\_config](#input\_educates\_config) | n/a | <pre>object({<br/>    installer_oci_image    = optional(string, "ghcr.io/educates/educates-installer")<br/>    version                = optional(string, "3.3.2")<br/>    config_file            = optional(string, "educates-app-config.yaml")<br/>    config_is_to_be_merged = optional(bool, true)<br/>    install                = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_gcp_config"></a> [gcp\_config](#input\_gcp\_config) | #### GCP #### | <pre>object({<br/>    cluster_name = string<br/>    project      = string<br/>    dns_zone     = string<br/>  })</pre> | <pre>{<br/>  "cluster_name": "",<br/>  "dns_zone": "",<br/>  "project": ""<br/>}</pre> | no |
| <a name="input_infrastructure_provider"></a> [infrastructure\_provider](#input\_infrastructure\_provider) | Infrastructure provider | `string` | n/a | yes |
| <a name="input_wildcard_domain"></a> [wildcard\_domain](#input\_wildcard\_domain) | Wildcard domain to use for services deployed in the cluster | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_educates"></a> [educates](#output\_educates) | n/a |
