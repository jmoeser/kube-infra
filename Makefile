SHELL:=/bin/bash

up:
	kind create cluster --config kind-config.yaml
	export KUBECONFIG=$$(kind get kubeconfig-path)
	sleep 10
	kubectl get nodes

down:
	kind delete cluster

unittests:
	bin/runTests.sh

test:
	cd tests && go test -v
