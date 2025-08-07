terraform {
  required_providers {
    # CRITICAL: This provider is essential for deploying kapp-controller and custom resources
    # The alekc/kubectl provider is required because:
    # 1. It supports advanced wait conditions with field-based waiting
    # 2. It can deploy complex YAML manifests including CRDs
    # 3. It supports multi-document YAML processing
    # 4. The official hashicorp/kubernetes provider cannot handle these requirements
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1.3"  # Pinned to specific version for stability
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
  required_version = ">= 1.5.0"
}