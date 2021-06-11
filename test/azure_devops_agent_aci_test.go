package test

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/microsoft/azure-devops-go-api/azuredevops"
	"github.com/microsoft/azure-devops-go-api/azuredevops/taskagent"
)

// This function tests the deployment of Azure DevOps Linux agents
func TestDeployAzureDevOpsLinuxAgents(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture/linux-agents"

	// generate a random suffix for the test
	rand.Seed(time.Now().UnixNano())
	randomInt := rand.Intn(9999)
	randomSuffix := strconv.Itoa(randomInt)
	os.Setenv("TF_VAR_random_suffix", randomSuffix)

	// randomize the agent pool name
	devopsPoolName := os.Getenv("TF_VAR_azure_devops_pool_name")
	testPoolName := fmt.Sprintf("%s-%s", devopsPoolName, randomSuffix)
	os.Setenv("TF_VAR_azure_devops_pool_name", testPoolName)

	devopsOrganizationName := os.Getenv("TF_VAR_azure_devops_org_name")
	devopsPersonalAccessToken := os.Getenv("TF_VAR_azure_devops_personal_access_token")
	devopsOrganizationURL := fmt.Sprintf("https://dev.azure.com/%s", devopsOrganizationName)

	defer deleteAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	err := createAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	if err != nil {
		t.Fatalf("Cannot create Azure DevOps agent pool for the test: %v", err)
	}

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check whether the length of output meets the requirement
	test_structure.RunTestStage(t, "validate", func() {
		// add wait time for ACI to get connectivity
		time.Sleep(45 * time.Second)

		// ensure deployment was successful
		expectedAgentsCount := 2
		actualAgentsCount, err := getAgentsCount(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

		if err != nil {
			t.Fatalf("Cannot retrieve the number of agents that were deployed: %v", err)
		}

		if expectedAgentsCount != actualAgentsCount {
			t.Fatalf("Test failed. Expected number of agents is %d. Actual number of agents is %d", expectedAgentsCount, actualAgentsCount)
		}
	})

	// At the end of the test, clean up any resources that were created
	test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})
}

// This function tests the deployment of Azure DevOps Linux agents into an existing virtual network
func TestDeployAzureDevOpsLinuxAgentsInVirtualNetwork(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture/linux-agents-vnet"

	// generate a random suffix for the test
	rand.Seed(time.Now().UnixNano())
	randomInt := rand.Intn(9999)
	randomSuffix := strconv.Itoa(randomInt)
	os.Setenv("TF_VAR_random_suffix", randomSuffix)

	// randomize the agent pool name
	devopsPoolName := os.Getenv("TF_VAR_azure_devops_pool_name")
	testPoolName := fmt.Sprintf("%s-%s", devopsPoolName, randomSuffix)
	os.Setenv("TF_VAR_azure_devops_pool_name", testPoolName)
	// reset env var after test
	defer os.Setenv("TF_VAR_azure_devops_pool_name", devopsPoolName)

	devopsOrganizationName := os.Getenv("TF_VAR_azure_devops_org_name")
	devopsPersonalAccessToken := os.Getenv("TF_VAR_azure_devops_personal_access_token")
	devopsOrganizationURL := fmt.Sprintf("https://dev.azure.com/%s", devopsOrganizationName)

	defer deleteAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	err := createAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	if err != nil {
		t.Fatalf("Cannot create Azure DevOps agent pool for the test: %v", err)
	}

	// At the end of the test, clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check whether the length of output meets the requirement
	test_structure.RunTestStage(t, "validate", func() {
		// add wait time for ACI to get connectivity
		time.Sleep(45 * time.Second)

		// ensure deployment was successful
		expectedAgentsCount := 2
		actualAgentsCount, err := getAgentsCount(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

		if err != nil {
			t.Fatalf("Cannot retrieve the number of agents that were deployed: %v", err)
		}

		if expectedAgentsCount != actualAgentsCount {
			t.Fatalf("Test failed. Expected number of agents is %d. Actual number of agents is %d", expectedAgentsCount, actualAgentsCount)
		}
	})
}

// This function tests the deployment of Azure DevOps Linux and Windows agents
func TestDeployAzureDevOpsLinuxAndWindowsAgents(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture/linux-and-windows-agents"

	// generate a random suffix for the test
	rand.Seed(time.Now().UnixNano())
	randomInt := rand.Intn(9999)
	randomSuffix := strconv.Itoa(randomInt)
	os.Setenv("TF_VAR_random_suffix", randomSuffix)

	// create random Linux agent pool name
	linuxTestPoolName := fmt.Sprintf("linux-e2e-agents-%s", randomSuffix)
	os.Setenv("TF_VAR_linux_azure_devops_pool_name", linuxTestPoolName)

	// create random Windows agent pool name
	windowsTestPoolName := fmt.Sprintf("windows-e2e-agents-%s", randomSuffix)
	os.Setenv("TF_VAR_windows_azure_devops_pool_name", windowsTestPoolName)

	devopsOrganizationName := os.Getenv("TF_VAR_azure_devops_org_name")
	devopsPersonalAccessToken := os.Getenv("TF_VAR_azure_devops_personal_access_token")
	devopsOrganizationURL := fmt.Sprintf("https://dev.azure.com/%s", devopsOrganizationName)

	// create the Linux agents pool
	defer deleteAzureDevOpsAgentTestPool(linuxTestPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	err := createAzureDevOpsAgentTestPool(linuxTestPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	if err != nil {
		t.Fatalf("Cannot create Azure DevOps Linux agent pool for the test: %v", err)
	}

	// create the Windows agents pool
	defer deleteAzureDevOpsAgentTestPool(windowsTestPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	err = createAzureDevOpsAgentTestPool(windowsTestPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	if err != nil {
		t.Fatalf("Cannot create Azure DevOps Linux agent pool for the test: %v", err)
	}

		// At the end of the test, clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check whether the length of output meets the requirement
	test_structure.RunTestStage(t, "validate", func() {
		// add wait time for ACI to get connectivity + pull Windows image
		time.Sleep(150 * time.Second)

		// ensure deployment was successful for Linux agents
		expectedLinuxAgentsCount := 2
		actualLinuxAgentsCount, err := getAgentsCount(linuxTestPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

		if err != nil {
			t.Fatalf("Cannot retrieve the number of Linux agents that were deployed: %v", err)
		}

		if expectedLinuxAgentsCount != actualLinuxAgentsCount {
			t.Fatalf("Test failed. Expected number of Linux agents is %d. Actual number of Linux agents is %d", expectedLinuxAgentsCount, actualLinuxAgentsCount)
		}

		// ensure deployment was successful for Windows agents
		expectedWindowsAgentsCount := 2
		actualWindowsAgentsCount, err := getAgentsCount(windowsTestPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

		if err != nil {
			t.Fatalf("Cannot retrieve the number of Windows agents that were deployed: %v", err)
		}

		if expectedWindowsAgentsCount != actualWindowsAgentsCount {
			t.Fatalf("Test failed. Expected number of Windows agents is %d. Actual number of Windows agents is %d", expectedWindowsAgentsCount, actualWindowsAgentsCount)
		}
	})
}

// This function tests the deployment of Azure DevOps Linux agents into an existing resource group
func TestDeployAzureDevOpsLinuxAgentsIntoExistingRresourceGroup(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture/linux-agents-import-rg"

	// generate a random suffix for the test
	rand.Seed(time.Now().UnixNano())
	randomInt := rand.Intn(9999)
	randomSuffix := strconv.Itoa(randomInt)
	os.Setenv("TF_VAR_random_suffix", randomSuffix)

	// randomize the agent pool name
	devopsPoolName := os.Getenv("TF_VAR_azure_devops_pool_name")
	testPoolName := fmt.Sprintf("%s-%s", devopsPoolName, randomSuffix)
	os.Setenv("TF_VAR_azure_devops_pool_name", testPoolName)

	devopsOrganizationName := os.Getenv("TF_VAR_azure_devops_org_name")
	devopsPersonalAccessToken := os.Getenv("TF_VAR_azure_devops_personal_access_token")
	devopsOrganizationURL := fmt.Sprintf("https://dev.azure.com/%s", devopsOrganizationName)

	defer deleteAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	err := createAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	if err != nil {
		t.Fatalf("Cannot create Azure DevOps agent pool for the test: %v", err)
	}


	// At the end of the test, clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check whether the length of output meets the requirement
	test_structure.RunTestStage(t, "validate", func() {
		// add wait time for ACI to get connectivity
		time.Sleep(45 * time.Second)

		// ensure deployment was successful
		expectedAgentsCount := 2
		actualAgentsCount, err := getAgentsCount(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

		if err != nil {
			t.Fatalf("Cannot retrieve the number of agents that were deployed: %v", err)
		}

		if expectedAgentsCount != actualAgentsCount {
			t.Fatalf("Test failed. Expected number of agents is %d. Actual number of agents is %d", expectedAgentsCount, actualAgentsCount)
		}
	})
}

// This function tests the deployment of Azure DevOps Linux
func TestAgentCleanUp(t *testing.T) {
	t.Parallel()

	fixtureFolder := "./fixture/agent-pool-cleanup"

	// generate a random suffix for the test
	rand.Seed(time.Now().UnixNano())
	randomInt := rand.Intn(9999)
	randomSuffix := strconv.Itoa(randomInt)


	// create random agent pool name
	testPoolName := fmt.Sprintf("e2e-agents-%s", randomSuffix)
	os.Setenv("TF_VAR_linux_azure_devops_pool_name", testPoolName)
	os.Setenv("TF_VAR_windows_azure_devops_pool_name", testPoolName)

	devopsOrganizationName := os.Getenv("TF_VAR_azure_devops_org_name")
	devopsPersonalAccessToken := os.Getenv("TF_VAR_azure_devops_personal_access_token")
	devopsOrganizationURL := fmt.Sprintf("https://dev.azure.com/%s", devopsOrganizationName)

	// create the Linux agents pool
	defer deleteAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	err := createAzureDevOpsAgentTestPool(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)
	if err != nil {
		t.Fatalf("Cannot create Azure DevOps Linux agent pool for the test: %v", err)
	}


	// At the end of the test, clean up any resources that were created
	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraform.Destroy(t, terraformOptions)
	})

	// Deploy the example
	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := configureTerraformOptions(t, fixtureFolder)

		// Save the options so later test stages can use them
		test_structure.SaveTerraformOptions(t, fixtureFolder, terraformOptions)

		// This will init and apply the resources and fail the test if there are any errors
		terraform.InitAndApply(t, terraformOptions)
	})

	// Check whether the length of output meets the requirement
	test_structure.RunTestStage(t, "validate", func() {
		// add wait time for ACI to get connectivity
		time.Sleep(45 * time.Second)

		// ensure deployment was successful for agents
		expectedAgentsCount := 2
		actualAgentsCount, err := getAgentsCount(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

		if err != nil {
			t.Fatalf("Cannot retrieve the number of agents that were deployed: %v", err)
		}

		if expectedAgentsCount != actualAgentsCount {
			t.Fatalf("Test failed. Expected number of agents is %d. Actual number of agents is %d", expectedAgentsCount, actualAgentsCount)
		}

		// Update agent count
		terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
		terraformOptions.Vars["agents_count"] = "1"
		terraform.Apply(t, terraformOptions)
		// add wait time for ACI to update
		time.Sleep(45 * time.Second)

		expectedAgentsCount = 1
		actualAgentsCount, err = getAgentsCount(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

		if err != nil {
			t.Fatalf("Cannot retrieve the number of agents that were deployed: %v", err)
		}

		if expectedAgentsCount != actualAgentsCount {
			t.Fatalf("Test failed. Expected number of agents is %d. Actual number of agents is %d", expectedAgentsCount, actualAgentsCount)
		}
// destroying infrastructure:
terraformOptions := test_structure.LoadTerraformOptions(t, fixtureFolder)
terraform.Destroy(t, terraformOptions)

// after clean up, new expected count = 0
expectedAgentsCount = 0
actualAgentsCount, err = getAgentsCount(testPoolName, devopsOrganizationURL, devopsPersonalAccessToken)

if err != nil {
	t.Fatalf("Cannot retrieve the number of agents that were deployed: %v", err)
}

if expectedAgentsCount != actualAgentsCount {
	t.Fatalf("Test failed. Expected number of agents is %d. Actual number of agents is %d", expectedAgentsCount, actualAgentsCount)
}
	})
}

func configureTerraformOptions(t *testing.T, fixtureFolder string) *terraform.Options {

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: fixtureFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{},
	}

	return terraformOptions
}

func getAgentsCount(devopsPoolName string, devopsOrganizationURL string, devopsPersonalAccessToken string) (int, error) {
	ctx := context.Background()
	devopsConnection := azuredevops.NewPatConnection(devopsOrganizationURL, devopsPersonalAccessToken)
	devopsTaskAgentClient, err := taskagent.NewClient(ctx, devopsConnection)
	if err != nil {
		return -1, err
	}

	agentPool, err := getAgentPool(ctx, devopsTaskAgentClient, devopsPoolName)
	if err != nil {
		return -1, err
	}

	getAgentsArgs := taskagent.GetAgentsArgs{
		PoolId: agentPool.Id,
	}

	agents, err := devopsTaskAgentClient.GetAgents(ctx, getAgentsArgs)
	if err != nil {
		return -1, err
	}

	return len(*agents), nil
}

func createAzureDevOpsAgentTestPool(devopsPoolName string, devopsOrganizationURL string, devopsPersonalAccessToken string) error {
	ctx := context.Background()
	devopsConnection := azuredevops.NewPatConnection(devopsOrganizationURL, devopsPersonalAccessToken)
	devopsTaskAgentClient, err := taskagent.NewClient(ctx, devopsConnection)
	if err != nil {
		return err
	}

	addAgentPoolArgs := taskagent.AddAgentPoolArgs{
		Pool: &taskagent.TaskAgentPool{
			Name:     &devopsPoolName,
			PoolType: &taskagent.TaskAgentPoolTypeValues.Automation,
		},
	}

	_, err = devopsTaskAgentClient.AddAgentPool(ctx, addAgentPoolArgs)
	if err != nil {
		return err
	}

	return nil
}

func deleteAzureDevOpsAgentTestPool(devopsPoolName string, devopsOrganizationURL string, devopsPersonalAccessToken string) error {
	ctx := context.Background()
	devopsConnection := azuredevops.NewPatConnection(devopsOrganizationURL, devopsPersonalAccessToken)
	devopsTaskAgentClient, err := taskagent.NewClient(ctx, devopsConnection)
	if err != nil {
		return err
	}

	agentPoolToDelete, err := getAgentPool(ctx, devopsTaskAgentClient, devopsPoolName)
	if err != nil {
		return err
	}

	deleteAgentPoolArgs := taskagent.DeleteAgentPoolArgs{
		PoolId: agentPoolToDelete.Id,
	}

	return devopsTaskAgentClient.DeleteAgentPool(ctx, deleteAgentPoolArgs)
}

func getAgentPool(ctx context.Context, devopsTaskAgentClient taskagent.Client, devopsPoolName string) (*taskagent.TaskAgentPool, error) {
	getAgentPoolsArgs := taskagent.GetAgentPoolsArgs{
		PoolName: &devopsPoolName,
	}

	matchingAgentPools, err := devopsTaskAgentClient.GetAgentPools(ctx, getAgentPoolsArgs)
	if err != nil {
		return nil, err
	}

	if matchingAgentPools == nil || len(*matchingAgentPools) == 0 {
		return nil, fmt.Errorf("Cannot find an agent pool that matches name: %s", devopsPoolName)
	}

	return &(*matchingAgentPools)[0], nil
}
