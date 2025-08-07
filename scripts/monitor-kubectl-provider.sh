#!/bin/bash

# Monitor kubectl provider updates and compatibility
# This script checks for new versions of the alekc/kubectl provider
# and tests compatibility with our modules

set -e

# Configuration
CURRENT_VERSION="2.1.3"
PROVIDER_NAME="alekc/kubectl"
TERRAFORM_REGISTRY_URL="https://registry.terraform.io/v1/providers/${PROVIDER_NAME}/versions"
TEST_DIR="platform/educates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        log_error "terraform is required but not installed. Please install terraform first."
        exit 1
    fi
}

# Get latest version from Terraform registry
get_latest_version() {
    log_info "Fetching latest version from Terraform registry..."
    
    # Get the latest version from the registry
    LATEST_VERSION=$(curl -s "${TERRAFORM_REGISTRY_URL}" | jq -r '.versions | keys | .[]' | sort -V | tail -n1)
    
    if [ -z "$LATEST_VERSION" ]; then
        log_error "Failed to fetch latest version from registry"
        exit 1
    fi
    
    log_info "Latest version: ${LATEST_VERSION}"
    echo "$LATEST_VERSION"
}

# Compare versions
compare_versions() {
    local current=$1
    local latest=$2
    
    if [ "$current" = "$latest" ]; then
        log_success "Current version ($current) is up to date"
        return 0
    else
        log_warning "New version available: $latest (current: $current)"
        return 1
    fi
}

# Test provider compatibility
test_provider_compatibility() {
    local version=$1
    local test_name=$2
    
    log_info "Testing kubectl provider version $version..."
    
    # Create temporary directory for testing
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Copy test files
    cp -r "$TEST_DIR"/* "$temp_dir/"
    
    # Create temporary versions.tf with specific version
    cat > "$temp_dir/versions.tf" <<EOF
terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "$version"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
  required_version = ">= 1.5.0"
}
EOF
    
    # Create minimal test configuration
    cat > "$temp_dir/test.tfvars" <<EOF
infrastructure_provider = "kind"
wildcard_domain        = "test.local"
educates_app = {
  namespace = "test-educates"
}
EOF
    
    # Test terraform init
    cd "$temp_dir"
    if terraform init -input=false > /dev/null 2>&1; then
        log_success "Provider version $version: terraform init successful"
        
        # Test terraform plan (dry run)
        if terraform plan -var-file=test.tfvars -input=false > /dev/null 2>&1; then
            log_success "Provider version $version: terraform plan successful"
            return 0
        else
            log_error "Provider version $version: terraform plan failed"
            return 1
        fi
    else
        log_error "Provider version $version: terraform init failed"
        return 1
    fi
}

# Generate compatibility report
generate_report() {
    local current_version=$1
    local latest_version=$2
    local compatibility_status=$3
    
    local report_file="kubectl-provider-report-$(date +%Y%m%d).md"
    
    cat > "$report_file" <<EOF
# kubectl Provider Compatibility Report

**Generated:** $(date)
**Current Version:** $current_version
**Latest Version:** $latest_version

## Summary

- **Provider:** $PROVIDER_NAME
- **Current Version:** $current_version
- **Latest Version:** $latest_version
- **Compatibility:** $compatibility_status

## Recommendations

EOF
    
    if [ "$current_version" != "$latest_version" ]; then
        cat >> "$report_file" <<EOF
### Version Update Available

A new version ($latest_version) is available. Consider updating if:

1. The new version includes security fixes
2. The new version includes bug fixes relevant to your use case
3. You need new features from the latest version

### Testing Required

Before updating to version $latest_version:

1. Run this script to test compatibility
2. Test in a non-production environment
3. Verify all kubectl_manifest resources work correctly
4. Check for any breaking changes in the provider's changelog

EOF
    else
        cat >> "$report_file" <<EOF
### No Update Required

The current version ($current_version) is the latest available version.

EOF
    fi
    
    cat >> "$report_file" <<EOF
## Critical Dependencies

This provider is essential for the educates platform module due to:

1. **Advanced Wait Conditions**: Field-based waiting for complex status conditions
2. **YAML Manifest Support**: Direct deployment of complex YAML manifests including CRDs
3. **Multi-document Processing**: Handling of multi-document YAML files
4. **Custom Resource Support**: Deployment of kapp-controller's custom resources

## Monitoring

This script should be run regularly to:

- Monitor for new provider versions
- Test compatibility with new versions
- Ensure security updates are applied
- Maintain provider version documentation

## Next Steps

1. Review this report
2. Test any new versions in development environment
3. Update provider version if compatibility is confirmed
4. Update documentation and version constraints
EOF
    
    log_success "Report generated: $report_file"
}

# Main execution
main() {
    log_info "Starting kubectl provider monitoring..."
    
    # Check dependencies
    check_dependencies
    
    # Get latest version
    latest_version=$(get_latest_version)
    
    # Compare versions
    if compare_versions "$CURRENT_VERSION" "$latest_version"; then
        compatibility_status="✅ Compatible (Current version is latest)"
    else
        # Test compatibility with latest version
        if test_provider_compatibility "$latest_version" "latest"; then
            compatibility_status="✅ Compatible (Latest version tested successfully)"
        else
            compatibility_status="❌ Incompatible (Latest version failed tests)"
        fi
    fi
    
    # Generate report
    generate_report "$CURRENT_VERSION" "$latest_version" "$compatibility_status"
    
    log_success "Monitoring complete"
}

# Run main function
main "$@"
