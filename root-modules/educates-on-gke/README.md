# Educates on GKE

This module will create a GKE cluster and then provision Educates 3.x on top

## Configuration

Create a file named `main.tfvars` and place all the required configuration there

There's an example configuration file at [examples/main.tfvars.example](examples/main.tfvars.example)

## How to run

### Create

```
terraform apply -var-file main.tfvars
```

### Destroy

```
terraform destroy -var-file main.tfvars
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_educates"></a> [educates](#module\_educates) | ../../platform/educates | n/a |
| <a name="module_gke_for_educates"></a> [gke\_for\_educates](#module\_gke\_for\_educates) | ../../infrastructure/gke-for-educates | n/a |
| <a name="module_token-sa-kubeconfig"></a> [token-sa-kubeconfig](#module\_token-sa-kubeconfig) | ../../infrastructure/token-sa-kubeconfig | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TLD"></a> [TLD](#input\_TLD) | Top Level Domain to use for services deployed in the cluster (cluster\_name will be prepended for final wildcard\_domain) | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name to use | `string` | n/a | yes |
| <a name="input_educates_version"></a> [educates\_version](#input\_educates\_version) | Educates version to use | `string` | `"3.3.2"` | no |
| <a name="input_kubeconfig_file"></a> [kubeconfig\_file](#input\_kubeconfig\_file) | Path to the kubeconfig file | `string` | `""` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version of kubernetes cluster to create | `string` | `"1.31"` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Node groups for the cluster | <pre>list(object({<br/>    name               = string<br/>    machine_type       = optional(string, "e2-medium")<br/>    min_count          = optional(number, 1)<br/>    max_count          = optional(number, 6)<br/>    initial_node_count = optional(number, 3)<br/>    disk_size_gb       = optional(number, 100)<br/>    disk_type          = optional(string, "pd-balanced") # "pd-standard", "pd-balanced", "pd-ssd"<br/>    image_type         = optional(string,"COS_CONTAINERD")<br/>    auto_repair        = optional(bool, true)<br/>    auto_upgrade       = optional(bool, true)<br/>    preemptible        = optional(bool, false)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "default-node-pool"<br/>  }<br/>]</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_educates"></a> [educates](#output\_educates) | n/a |
| <a name="output_gke"></a> [gke](#output\_gke) | n/a |
| <a name="output_kubernetes"></a> [kubernetes](#output\_kubernetes) | n/a |
| <a name="output_token-sa-kubeconfig"></a> [token-sa-kubeconfig](#output\_token-sa-kubeconfig) | n/a |
