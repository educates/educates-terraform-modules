# Educates on GKE

This module will create a GKE cluster and then provision Educates 3.x on top

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
