SHELL := /bin/sh
JSONNET_FMT := jsonnetfmt -n 4 --max-blank-lines 2 --string-style s --comment-style s

up:
	kind create cluster --config kind-config.yaml
	sleep 10
	KUBECONFIG=$$(kind get kubeconfig-path) kubectl get nodes

down:
	kind delete cluster

validate:
	bin/runValidation.sh

test:
	bin/runTests.sh
#	cd tests && go test -v

fmt:
	find . -name '*.libsonnet' -o -name '*.jsonnet' | \
		xargs -n 1 -- $(JSONNET_FMT) -i
