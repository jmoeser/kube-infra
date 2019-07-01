#!/bin/bash

for FILE in apps/*/tests/main.jsonnet ; do
    echo "Testing $FILE..."
    echo "Validate Kubernetes YAML"
    kubecfg show -o yaml "$FILE" | kubeval
    echo "Validate YAML against required policies"
    kubecfg show -o yaml "$FILE" | conftest test -
done
