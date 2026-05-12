package terratest

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/require"
)

func TestExamples(t *testing.T) {
	examplesDir := repoExamplesDir(t)
	examples := exampleDirectories(t, examplesDir)

	selectedExample := os.Getenv("TERRATEST_EXAMPLE")
	if selectedExample != "" {
		require.Contains(t, examples, selectedExample, "TERRATEST_EXAMPLE must match an example directory")
		examples = []string{selectedExample}
	}

	if missingAzureCredentials() {
		t.Skip("Skipping terratest examples because ARM_CLIENT_ID, ARM_TENANT_ID, or ARM_SUBSCRIPTION_ID is not set.")
	}

	for _, example := range examples {
		t.Run(example, func(t *testing.T) {
			terraformDirectory := test_structure.CopyTerraformFolderToTemp(t, filepath.Dir(examplesDir), filepath.Join("examples", example))

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: terraformDirectory,
				EnvVars: map[string]string{
					"TF_IN_AUTOMATION":        "1",
					"TF_VAR_enable_telemetry": "false",
				},
				MaxRetries:         3,
				TimeBetweenRetries: 10 * time.Second,
				NoColor:            true,
			})

			defer func() {
				if _, err := terraform.DestroyE(t, terraformOptions); err != nil {
					t.Logf("terraform destroy for %s returned: %v", example, err)
				}
			}()

			terraform.InitAndApplyAndIdempotent(t, terraformOptions)
		})
	}
}

func repoExamplesDir(t *testing.T) string {
	t.Helper()

	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	require.NoError(t, err)

	return filepath.Join(repoRoot, "examples")
}

func exampleDirectories(t *testing.T, examplesDir string) []string {
	t.Helper()

	entries, err := os.ReadDir(examplesDir)
	require.NoError(t, err)

	examples := make([]string, 0, len(entries))
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		exampleDir := filepath.Join(examplesDir, entry.Name())
		if _, err := os.Stat(filepath.Join(exampleDir, ".e2eignore")); err == nil {
			continue
		} else if err != nil && !os.IsNotExist(err) {
			require.NoError(t, err)
		}

		examples = append(examples, entry.Name())
	}

	slices.Sort(examples)
	require.NotEmpty(t, examples, fmt.Sprintf("no example directories found in %s", examplesDir))

	return examples
}

func missingAzureCredentials() bool {
	requiredEnvVars := []string{
		"ARM_CLIENT_ID",
		"ARM_TENANT_ID",
		"ARM_SUBSCRIPTION_ID",
	}

	for _, envVar := range requiredEnvVars {
		if os.Getenv(envVar) == "" {
			return true
		}
	}

	return false
}
