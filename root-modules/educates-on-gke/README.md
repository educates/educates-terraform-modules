# Educates on GKE

This module will create a GKE cluster and then provision Educates 3.x on top

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
