# Educates on EKS

This module will create a EKS cluster and then provision Educates 3.x on top

## Configuration

Create a file named `environment.tfvars` and place all the required configuration there

## How to run

### Create

```
terraform apply -var-file environment.tfvars -auto-approve
```

### Destroy

```
terraform destroy -var-file environment.tfvars -auto-approve
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.94.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_educates"></a> [educates](#module\_educates) | ../../platform/educates | n/a |
| <a name="module_eks_for_educates"></a> [eks\_for\_educates](#module\_eks\_for\_educates) | ../../infrastructure/eks-for-educates | n/a |
| <a name="module_token-sa-kubeconfig"></a> [token-sa-kubeconfig](#module\_token-sa-kubeconfig) | ../../infrastructure/token-sa-kubeconfig | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_TLD"></a> [TLD](#input\_TLD) | Top Level Domain to use for services deployed in the cluster (cluster\_name will be prepended for final wildcard\_domain) | `string` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | Account id of the AWS user. Can get with `aws sts get-caller-identity` | `string` | n/a | yes |
| <a name="input_aws_auth_roles"></a> [aws\_auth\_roles](#input\_aws\_auth\_roles) | n/a | <pre>list(object({<br/>    groups   = list(string)<br/>    rolearn  = string<br/>    username = string<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_auth_users"></a> [aws\_auth\_users](#input\_aws\_auth\_users) | n/a | <pre>list(object({<br/>    groups   = list(string)<br/>    userarn  = string<br/>    username = string<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name to use | `string` | n/a | yes |
| <a name="input_educates_version"></a> [educates\_version](#input\_educates\_version) | Educates version to use | `string` | `"3.2.2"` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | n/a | `list(string)` | `[]` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version of kubernetes cluster to create | `string` | `"1.31"` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | n/a | `bool` | n/a | yes |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Node groups for the cluster | <pre>map(object({<br/>    name                          = string<br/>    desired_size                  = optional(number, 3)<br/>    max_size                      = optional(number, 6)<br/>    min_size                      = optional(number, 2)<br/>    instance_types                = optional(list(string), ["c6i.xlarge"])<br/>    disk_size                     = optional(number, 100)<br/>    use_custom_launch_template    = optional(bool, false)<br/>    iam_role_permissions_boundary = optional(string)<br/>  }))</pre> | <pre>{<br/>  "one": {<br/>    "name": "node-group-1"<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_educates"></a> [educates](#output\_educates) | n/a |
| <a name="output_eks"></a> [eks](#output\_eks) | n/a |
| <a name="output_kubernetes"></a> [kubernetes](#output\_kubernetes) | n/a |
| <a name="output_token-sa-kubeconfig"></a> [token-sa-kubeconfig](#output\_token-sa-kubeconfig) | n/a |