# Testing Strategy for Educates Terraform Modules

## Overview

This document outlines the recommended testing strategy for the Educates Terraform modules, considering the complexity of the infrastructure, the critical dependency on the `alekc/kubectl` provider, and the need for reliable deployments.

## Testing Challenges

### Current State
- **No existing tests**: The codebase currently lacks any testing framework
- **Complex dependencies**: Multiple providers, custom resources, and cross-module dependencies
- **Cost considerations**: Testing infrastructure modules requires actual cloud resources
- **Time constraints**: Full infrastructure deployment takes significant time

## Recommended Testing Strategy

### 1. Unit Testing with Terratest

#### Setup
```bash
# Install Go and Terratest
go mod init educates-terraform-tests
go get github.com/gruntwork-io/terratest/modules/terraform
go get github.com/gruntwork-io/terratest/modules/k8s
```

#### Test Structure
```
tests/
├── unit/
│   ├── gke-module/
│   │   ├── service_account_naming_test.go
│   │   └── outputs_test.go
│   ├── platform-module/
│   │   ├── config_validation_test.go
│   │   └── provider_dependency_test.go
│   └── root-modules/
│       ├── gke-integration_test.go
│       └── eks-integration_test.go
├── integration/
│   ├── full-gke-deployment_test.go
│   └── full-eks-deployment_test.go
└── fixtures/
    ├── gke-test-config/
    └── eks-test-config/
```

#### Example Unit Test
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestGKEServiceAccountNaming(t *testing.T) {
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../../infrastructure/gke-for-educates",
        Vars: map[string]interface{}{
            "cluster_name": "test-cluster-with-very-long-name-that-exceeds-limits",
            "project_id":   "test-project",
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndPlan(t, terraformOptions)

    // Test that service account names are properly truncated
    outputs := terraform.Output(t, terraformOptions, "gke")
    assert.Contains(t, outputs, "certmanager_service_account")
    assert.Contains(t, outputs, "externaldns_service_account")
}
```

### 2. Integration Testing with Kind (Kubernetes in Docker)

#### Benefits
- **Fast execution**: Local Kubernetes cluster
- **No cloud costs**: Uses Docker containers
- **Realistic testing**: Actual Kubernetes API
- **Isolated environment**: Each test gets a fresh cluster

#### Setup
```yaml
# tests/integration/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
```

#### Example Integration Test
```go
func TestEducatesPlatformModule(t *testing.T) {
    // Create Kind cluster
    clusterName := "educates-test"
    kind.CreateCluster(t, clusterName, &kind.CreateClusterOptions{
        ConfigFile: "kind-config.yaml",
    })
    defer kind.DeleteCluster(t, clusterName)

    // Deploy kapp-controller
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../../platform/educates",
        Vars: map[string]interface{}{
            "infrastructure_provider": "kind",
            "wildcard_domain":        "test.local",
            "educates_app": map[string]interface{}{
                "namespace": "test-educates",
            },
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Verify kapp-controller deployment
    k8sOptions := k8s.NewKubectlOptions(clusterName, "", "")
    k8s.WaitUntilServiceAvailable(t, k8sOptions, "packaging-api", "kapp-controller", 10, 5*time.Second)
}
```

### 3. Provider Compatibility Testing

#### kubectl Provider Testing
```go
func TestKubectlProviderCompatibility(t *testing.T) {
    // Test different kubectl provider versions
    versions := []string{"2.1.0", "2.1.3", "2.2.0"}
    
    for _, version := range versions {
        t.Run(fmt.Sprintf("Version_%s", version), func(t *testing.T) {
            terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
                TerraformDir: "../../platform/educates",
                Vars: map[string]interface{}{
                    "infrastructure_provider": "kind",
                    "wildcard_domain":        "test.local",
                },
                // Override provider version
                RetryableTerraformErrors: map[string]string{
                    ".*": ".*",
                },
            })
            
            defer terraform.Destroy(t, terraformOptions)
            terraform.InitAndApply(t, terraformOptions)
        })
    }
}
```

### 4. Configuration Validation Testing

#### Test Config Merging
```go
func TestEducatesConfigMerging(t *testing.T) {
    testCases := []struct {
        name           string
        awsConfig      map[string]interface{}
        gcpConfig      map[string]interface{}
        expectedError  bool
    }{
        {
            name: "Valid AWS Config",
            awsConfig: map[string]interface{}{
                "account_id":   "123456789012",
                "cluster_name": "test-cluster",
                "region":       "us-west-2",
                "dns_zone":     "test.com",
            },
            expectedError: false,
        },
        {
            name: "Invalid AWS Config - Missing Account ID",
            awsConfig: map[string]interface{}{
                "cluster_name": "test-cluster",
                "region":       "us-west-2",
            },
            expectedError: true,
        },
    }

    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
                TerraformDir: "../../platform/educates",
                Vars: map[string]interface{}{
                    "infrastructure_provider": "aws",
                    "aws_config":             tc.awsConfig,
                    "wildcard_domain":        "test.local",
                },
            })

            if tc.expectedError {
                _, err := terraform.InitAndApplyE(t, terraformOptions)
                assert.Error(t, err)
            } else {
                defer terraform.Destroy(t, terraformOptions)
                terraform.InitAndApply(t, terraformOptions)
            }
        })
    }
}
```

### 5. Cloud-Specific Testing (Optional)

#### GKE Testing with Real Cluster
```go
func TestGKEIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping GKE integration test in short mode")
    }

    // Use test project and minimal resources
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../../root-modules/educates-on-gke",
        Vars: map[string]interface{}{
            "cluster_name": "test-educates-gke",
            "project_id":   "test-project-id",
            "node_groups": map[string]interface{}{
                "default": map[string]interface{}{
                    "desired_capacity": 1,
                    "max_capacity":     2,
                    "min_capacity":     1,
                },
            },
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
}
```

## Testing Infrastructure

### CI/CD Pipeline
```yaml
# .github/workflows/test.yml
name: Terraform Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    - run: |
        cd tests/unit
        go test -v ./...
  
  integration-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    - uses: actions/setup-docker@v3
    - run: |
        kind create cluster --name test-cluster
        cd tests/integration
        go test -v ./...
      finally:
        kind delete cluster --name test-cluster
```

### Test Data Management
```bash
# tests/fixtures/generate-test-data.sh
#!/bin/bash

# Generate test configurations
cat > tests/fixtures/gke-test-config/main.tfvars <<EOF
cluster_name = "test-educates-gke"
project_id   = "test-project-id"
node_groups = {
  default = {
    desired_capacity = 1
    max_capacity     = 2
    min_capacity     = 1
  }
}
EOF
```

## Monitoring and Alerting

### Test Metrics
- **Test execution time**: Track how long tests take to run
- **Provider compatibility**: Monitor kubectl provider version compatibility
- **Resource usage**: Track memory and CPU usage during tests
- **Failure rates**: Monitor test failure patterns

### Automated Alerts
```yaml
# .github/workflows/alerts.yml
name: Test Alerts
on:
  workflow_run:
    workflows: ["Terraform Tests"]
    types: [completed]

jobs:
  alert-on-failure:
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    runs-on: ubuntu-latest
    steps:
    - name: Send Alert
      run: |
        # Send notification to team
        echo "Terraform tests failed: ${{ github.event.workflow_run.html_url }}"
```

## Best Practices

### 1. Test Isolation
- Each test should create its own resources
- Use unique names for all resources
- Clean up resources even if tests fail

### 2. Parallel Testing
- Run unit tests in parallel
- Use separate Kind clusters for integration tests
- Limit concurrent cloud resource creation

### 3. Test Data Management
- Use fixtures for consistent test data
- Generate random names for resources
- Store test outputs for debugging

### 4. Documentation
- Document test setup requirements
- Include troubleshooting guides
- Maintain test coverage reports

## Implementation Priority

### Phase 1: Foundation (Week 1-2)
1. Set up Terratest framework
2. Create basic unit tests for service account naming
3. Set up Kind cluster for integration testing
4. Create CI/CD pipeline

### Phase 2: Core Testing (Week 3-4)
1. Add integration tests for platform module
2. Test kubectl provider compatibility
3. Add configuration validation tests
4. Implement test monitoring

### Phase 3: Advanced Testing (Week 5-6)
1. Add cloud-specific tests (optional)
2. Implement performance testing
3. Add security testing
4. Create comprehensive documentation

## Cost Considerations

### Testing Costs
- **Unit tests**: No cost (local execution)
- **Integration tests**: Minimal cost (Kind clusters)
- **Cloud tests**: ~$50-100/month for test infrastructure
- **CI/CD**: Free with GitHub Actions

### Cost Optimization
- Use spot instances for cloud testing
- Implement test timeouts
- Clean up resources aggressively
- Use smaller instance types for testing

## Conclusion

This testing strategy provides a comprehensive approach to ensuring the reliability of the Educates Terraform modules while managing costs and complexity. The phased implementation allows for gradual adoption and validation of the testing framework.
