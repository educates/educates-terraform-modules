# GKE Terraform module for Educates

This module will create a GKE cluster suitable to install Educates 3.x on top.

## Configuration

Create a file named `main.tfvars` and place all the required configuration there

There's an example configuration file at [main.tfvars.example](main.tfvars.example)

## How to run

### Create

```
terraform apply -var-file main.tfvars
```

### Destroy

```
terraform destroy -var-file main.tfvars
```

## Things to do
- [ ] Enable reuse of the default subnet. For now, a new VPC is created.
- [*] Create the 2 service accounts for the Educates cluster (external-dns and cert-manager) and attach them to GSA

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | 2.3.6 |
| <a name="requirement_google"></a> [google](#requirement\_google) | 6.28.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.36.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.28.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gke"></a> [gke](#module\_gke) | terraform-google-modules/kubernetes-engine/google | 36.2.0 |
| <a name="module_gke_auth"></a> [gke\_auth](#module\_gke\_auth) | terraform-google-modules/kubernetes-engine/google//modules/auth | 36.2.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-google-modules/network/google | ~> 10.0 |

## Resources

| Name | Type |
|------|------|
| [google_project_iam_binding.cert-manager-and-external-dns-as-dns-admin](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/resources/project_iam_binding) | resource |
| [google_service_account.cert-manager-gsa](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/resources/service_account) | resource |
| [google_service_account.default](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/resources/service_account) | resource |
| [google_service_account.external-dns-gsa](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/resources/service_account) | resource |
| [google_service_account_iam_binding.cert-manager-link-ksa-to-gsa](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/resources/service_account_iam_binding) | resource |
| [google_service_account_iam_binding.external-dns-link-ksa-to-gsa](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/resources/service_account_iam_binding) | resource |
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/data-sources/client_config) | data source |
| [google_compute_zones.this](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/data-sources/compute_zones) | data source |
| [google_container_engine_versions.gke_versions](https://registry.terraform.io/providers/hashicorp/google/6.28.0/docs/data-sources/container_engine_versions) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name to use | `string` | n/a | yes |
| <a name="input_kubeconfig_file"></a> [kubeconfig\_file](#input\_kubeconfig\_file) | Kubeconfig file (full path). Will default to kubeconfig\_<cluster\_name>.yaml in the current directory if not set | `string` | `""` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version of kubernetes cluster to create | `string` | `"1.31"` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Node groups for the cluster | <pre>list(object({<br/>    name               = string<br/>    machine_type       = optional(string, "e2-medium")<br/>    min_count          = optional(number, 3)<br/>    max_count          = optional(number, 3)<br/>    initial_node_count = optional(number, 3)<br/>    disk_size_gb       = optional(number, 100)<br/>    disk_type          = optional(string, "pd-balanced") # "pd-standard", "pd-balanced", "pd-ssd"<br/>    image_type         = optional(string,"COS_CONTAINERD")<br/>    auto_repair        = optional(bool, true)<br/>    auto_upgrade       = optional(bool, true)<br/>    preemptible        = optional(bool, false)<br/>    service_account    = optional(string, "default")<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "default-node-pool"<br/>  }<br/>]</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Account id of the GCP user | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | compute region where this cluster will live | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gke"></a> [gke](#output\_gke) | n/a |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | kubeconfig full path for the AWS EKS cluster |
| <a name="output_kubernetes"></a> [kubernetes](#output\_kubernetes) | # Some inspiration from: https://github.com/TykTechnologies/tyk-performance-testing/blob/main/modules/clouds/aws/main.tf |
| <a name="output_node_pools"></a> [node\_pools](#output\_node\_pools) | n/a |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | n/a |
| <a name="output_zones"></a> [zones](#output\_zones) | n/a |
