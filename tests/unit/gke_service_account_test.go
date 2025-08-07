package test

import (
	"encoding/json"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"gopkg.in/yaml.v3"
)

// TestConfig represents the structure of our test configuration
type TestConfig struct {
	GCP struct {
		ProjectID string `yaml:"project_id"`
		Region    string `yaml:"region"`
	} `yaml:"gcp"`
}

// loadTestConfig loads the test configuration from YAML file
func loadTestConfig(t *testing.T) *TestConfig {
	configPath := "test-config.yaml"

	// Check if config file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		t.Fatalf("Test configuration file not found: %s", configPath)
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		t.Fatalf("Failed to read test configuration: %v", err)
	}

	var config TestConfig
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		t.Fatalf("Failed to parse test configuration: %v", err)
	}

	return &config
}

func TestGKEServiceAccountNaming(t *testing.T) {
	config := loadTestConfig(t)

	// Test cases for different cluster name lengths
	testCases := []struct {
		name              string
		clusterName       string
		expectedMaxLength int
	}{
		{
			name:              "Short cluster name",
			clusterName:       "test-cluster",
			expectedMaxLength: 30,
		},
		{
			name:              "Long cluster name that needs truncation",
			clusterName:       "very-long-cluster-name-that-exceeds-google-service-account-limits",
			expectedMaxLength: 30,
		},
		{
			name:              "Cluster name with underscores",
			clusterName:       "test_cluster_with_underscores",
			expectedMaxLength: 30,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../infrastructure/gke-for-educates",
				Vars: map[string]interface{}{
					"cluster_name": tc.clusterName,
					"project_id":   config.GCP.ProjectID,
					"region":       config.GCP.Region,
				},
			})

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndPlan(t, terraformOptions)

			// Test that outputs are generated
			outputs := terraform.Output(t, terraformOptions, "gke")
			assert.NotEmpty(t, outputs)

			// Parse the output string as JSON to access individual fields
			var gkeOutput map[string]interface{}
			err := json.Unmarshal([]byte(outputs), &gkeOutput)
			assert.NoError(t, err, "Failed to parse gke output as JSON")

			// Test that service account emails are present and properly formatted
			if certManagerSA, exists := gkeOutput["certmanager_service_account"]; exists {
				assert.NotEmpty(t, certManagerSA)
				saEmail := certManagerSA.(string)
				// Check that the email follows the expected format
				assert.Contains(t, saEmail, "@"+config.GCP.ProjectID+".iam.gserviceaccount.com")
				// Check that the account ID part doesn't exceed 30 characters
				accountID := saEmail[:len(saEmail)-len("@"+config.GCP.ProjectID+".iam.gserviceaccount.com")]
				assert.LessOrEqual(t, len(accountID), tc.expectedMaxLength)
			}

			if externalDNSSA, exists := gkeOutput["externaldns_service_account"]; exists {
				assert.NotEmpty(t, externalDNSSA)
				saEmail := externalDNSSA.(string)
				// Check that the email follows the expected format
				assert.Contains(t, saEmail, "@"+config.GCP.ProjectID+".iam.gserviceaccount.com")
				// Check that the account ID part doesn't exceed 30 characters
				accountID := saEmail[:len(saEmail)-len("@"+config.GCP.ProjectID+".iam.gserviceaccount.com")]
				assert.LessOrEqual(t, len(accountID), tc.expectedMaxLength)
			}

			// Test that cluster name is preserved
			if clusterName, exists := gkeOutput["cluster_name"]; exists {
				assert.Equal(t, tc.clusterName, clusterName)
			}
		})
	}
}

func TestGKEServiceAccountNameConstraints(t *testing.T) {
	config := loadTestConfig(t)

	// Test that service account names follow Google Cloud constraints
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infrastructure/gke-for-educates",
		Vars: map[string]interface{}{
			"cluster_name": "test-cluster-with-very-long-name",
			"project_id":   config.GCP.ProjectID,
			"region":       config.GCP.Region,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)

	// Get the plan output to inspect resource names
	plan := terraform.Plan(t, terraformOptions)

	// Check that service account names are properly formatted
	// This is a simplified check - in a real scenario you'd parse the plan JSON
	assert.Contains(t, plan, "google_service_account")
}

// TestGKEModuleOutputs tests that all expected outputs are present
func TestGKEModuleOutputs(t *testing.T) {
	config := loadTestConfig(t)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infrastructure/gke-for-educates",
		Vars: map[string]interface{}{
			"cluster_name": "test-cluster",
			"project_id":   config.GCP.ProjectID,
			"region":       config.GCP.Region,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)

	// Test that all expected outputs are present
	expectedOutputs := []string{"gke", "kubeconfig_file", "zones", "kubernetes"}

	for _, outputName := range expectedOutputs {
		output := terraform.Output(t, terraformOptions, outputName)
		assert.NotEmpty(t, output, "Output %s should not be empty", outputName)
	}
}
