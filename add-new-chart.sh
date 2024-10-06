#!/bin/bash

# Define resources and patches
resources=(
  "../../../base/microservice1"
  "route.yaml"
  "namespace.yaml"
)

patches=(
  "path: patch-deployment.yaml"
  "target:
    kind: Deployment
    name: microservice1"
  "path: patch-service.yaml"
  "target:
    kind: Service
    name: microservice1"
)

# Example usage of resources and patches
echo "Resources:"
for resource in "${resources[@]}"; do
  echo "  - $resource"
done

echo "Patches:"
for patch in "${patches[@]}"; do
  echo "  - $patch"
done
