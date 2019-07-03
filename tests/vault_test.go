package test

import (
	"fmt"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"

	//"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
)

func TestVault(t *testing.T) {
	t.Parallel()

	jsonnetResourcePath, err := filepath.Abs("../apps/vault/tests/main.jsonnet")
	require.NoError(t, err)

	namespaceName := fmt.Sprintf("tests-%s", strings.ToLower(random.UniqueId()))

	t.Run("Validate", func(t *testing.T) {
		namespaceArg := fmt.Sprintf("namespace=%s", namespaceName)

		argsArray := []string{"show", "-o", "yaml", jsonnetResourcePath, "-V", namespaceArg}

		kubeCfgCommand := shell.Command{
			Command: "kubecfg",
			//Args:    []string{outputArg, jsonnetResourcePath, namespaceArg},
			Args: argsArray,
		}

		//kubecfgApplyResult := shell.RunCommandAndGetOutput(t, kubeCfgCommand)
		shell.RunCommandAndGetOutput(t, kubeCfgCommand)
	})

	//t.Log(kubecfgApplyResult)

	// // Setup the kubectl config and context. Here we choose to use the defaults, which is:
	// // - HOME/.kube/config for the kubectl config file
	// // - Current context of the kubectl config file
	// options := k8s.NewKubectlOptions("", "")

	// // To ensure we can reuse the resource config on the same cluster to test different scenarios, we setup a unique
	// // namespace for the resources for this test.
	// // Note that namespaces must be lowercase.
	// namespaceName := fmt.Sprintf("kubernetes-basic-example-%s", strings.ToLower(random.UniqueId()))
	// k8s.CreateNamespace(t, options, namespaceName)
	// // Make sure we set the namespace on the options
	// options.Namespace = namespaceName
	// // ... and make sure to delete the namespace at the end of the test
	// defer k8s.DeleteNamespace(t, options, namespaceName)

	// // At the end of the test, run `kubectl delete -f RESOURCE_CONFIG` to clean up any resources that were created.
	// defer k8s.KubectlDelete(t, options, kubeResourcePath)

	// // This will run `kubectl apply -f RESOURCE_CONFIG` and fail the test if there are any errors
	// k8s.KubectlApply(t, options, kubeResourcePath)

	// // This will get the service resource and verify that it exists and was retrieved successfully. This function will
	// // fail the test if the there is an error retrieving the service resource from Kubernetes.
	// service := k8s.GetService(t, options, "nginx-service")
	// require.Equal(t, service.Name, "nginx-service")
}
