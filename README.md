# Educates Terraform modules
Terraform modules used for Educates cluster management

This repository provides a set of reusable Terraform modules to create [Educates Infrastructure](./infrastructure/) such as an EKS or GKE cluster to be used for Educates, with all the typical pre-requisites satisfied, and there's modules to create the [Educates Platform](./platform/) on a cluster. 

There's also some [root-modules](./root-modules/) that serve as example showing how to get a full [Educates](educates.dev) full installation. These are not versioned.

- [gke](./root-modules/educates-on-gke/)

## Release a module

This repository uses https://github.com/techpivot/terraform-module-releaser to have GitHub Actions releasing the modules.
See configuration at [terraform-module-releaser.yaml](./.github/workflows/terraform-module-releaser.yaml)

To release:
- Create a PR from your branch to main with the following starting text at PR name or commit contained in the PR. It follows [Conventional commits](https://www.conventionalcommits.org/en/v1.0.0/):
    - To create a `major` release use `major change`,`major update` or `breaking change`
    - To create a minor release use `feat`,`feature`
    - To create a patch release use `fix`,`chore`,`docs`

__NOTE__: Initial release will not need to adhere to this rule

Examples:
- test: debugging outputs with changed module 
- fix: improve example variable
- feat: add another demo module

## TODO

- [x] Make this into educates-terraform-modules GitHub repository
- [x] Adopt best practices for module naming as suggested in https://github.com/techpivot/terraform-module-releaser
- [x] Make the modules releasable via https://github.com/techpivot/terraform-module-releaser
- [ ] Validate eks-for-educates module
- [ ] EKS root module
- [ ] Adopt terraform-docs for modules https://terraform-docs.io/
- [x] token-sa-kubeconfig module (working with EKS and GKE)
- [x] educates-gitops module
- [ ] sample root-module with educates-gitops