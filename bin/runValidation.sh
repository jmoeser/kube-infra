#!/bin/bash

for FILE in apps/*/tests/main.jsonnet ; do
    echo "Testing $FILE..."
    echo "Validate Kubernetes YAML"
    # --ignore-missing-schemas
    kubecfg show -o yaml "$FILE" -V namespace=tests | kubeval --skip-kinds Mapping --strict --filename="$FILE"
    echo "Validate YAML against required policies"
    kubecfg show -o yaml "$FILE" -V namespace=tests | conftest test -
done
