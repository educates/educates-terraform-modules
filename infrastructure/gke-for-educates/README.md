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