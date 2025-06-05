# Terraform module for Educates-gitops

This terraform module will deploy [Educates-gitops](https://github.com/educates/educates-workshop-gitops-configurer) on an Educates cluster as a Carvel Application

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 , < 2.0.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 2.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 2.0.4 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.clusterrolebinding_gitops_installs](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [kubectl_manifest.gitops_app](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [kubectl_manifest.gitops_credentials](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [kubectl_manifest.namespace_gitops_installs](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [kubectl_manifest.serviceaccount_gitops_installs](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [kubectl_manifest.theme](https://registry.terraform.io/providers/alekc/kubectl/2.0.4/docs/resources/manifest) | resource |
| [time_sleep.k8s_gitops_rbac](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitopsApp"></a> [gitopsApp](#input\_gitopsApp) | n/a | <pre>object({<br/>    namespace = optional(string, "workshop-gitops")<br/>    configFile = optional(string, "workshop-gitops-config.yaml")<br/>  })</pre> | `{}` | no |
| <a name="input_gitopsConfig"></a> [gitopsConfig](#input\_gitopsConfig) | n/a | <pre>object({<br/>    configRepo = optional(string, "https://github.com/educates/educates-workshop-gitops-configurer")<br/>    environment = optional(string, "sample-environment")<br/>    ref = optional(string, "origin/main")<br/>    subPathPrefix = optional(string, "config")<br/>    syncPeriod = optional(string, "0h10m0s")<br/>    overlaysBundle = optional(string, "ghcr.io/educates/educates-workshop-gitops-configurer:main")<br/>    github = optional(object({<br/>      username = optional(string, "")<br/>      password = optional(string, "")<br/>    }))<br/>    themeFile = optional(string, "theme.yaml")<br/>  })</pre> | <pre>{<br/>  "github": {}<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_educates-gitops"></a> [educates-gitops](#output\_educates-gitops) | n/a |
