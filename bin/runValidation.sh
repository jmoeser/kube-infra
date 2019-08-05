#!/bin/bash

for FILE in apps/*/tests/main.jsonnet ; do
    echo "Testing $FILE..."
    echo "Validate Kubernetes YAML"
    kubecfg show -o yaml "$FILE" -V namespace=tests | kubeval --strict --filename="$FILE"
    echo "Validate YAML against required policies"
    kubecfg show -o yaml "$FILE" -V namespace=tests | conftest test -
done
