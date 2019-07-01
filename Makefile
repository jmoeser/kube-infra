SHELL:=/bin/bash

up:
	kind create cluster --loglevel debug --config kind-config.yaml
	export KUBECONFIG=$(kind get kubeconfig-path)
	sleep 5
	kubectl get nodes

down:
	kind delete cluster

unittests:
	bin/runTests.sh
