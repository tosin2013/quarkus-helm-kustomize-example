#!/bin/bash

# Build a Helm chart first with the Helm command
helm create ziggy

# Run the following commands to view if your chart is rendering properly
helm template web ./ziggy

# I am only going to make use of the deployment, service, and pods, so all other templates I am going to delete.
rm -rf ziggy/templates/*

# Create the necessary directories
mkdir -p manifest overlays/dev overlays/prod

# Generate the Helm chart output
helm template web ziggy > manifest/backend.yaml

# Define the kustomize file under manifests
cat <<EOF > manifest/kustomization.yaml
resources:
  - "backend.yaml"
EOF

# Create the kustomization file for dev environment
cat <<EOF > overlays/dev/kustomization.yaml
resources:
  - "../../manifest/"
patches:
  - path: ./patch-deploy.yaml
    target:
      kind: Deployment
  - path: ./patch-service.yaml
    target:
      kind: Service
  - path: ./patch-pod.yaml
    target:
      kind: Pod
EOF

# Create the patch files for dev environment
cat <<EOF > overlays/dev/patch-deploy.yaml
- op: replace
  path: /metadata/name
  value: dev-ziggy-deployment
- op: add
  path: /spec/template/spec/containers/0/resources
  value:
    limits:
      cpu: "0.5"
      memory: "512Mi"
    requests:
      cpu: "0.2"
      memory: "256Mi"
EOF

cat <<EOF > overlays/dev/patch-service.yaml
- op: replace
  path: /metadata/name
  value: dev-ziggy-service
EOF

cat <<EOF > overlays/dev/patch-pod.yaml
- op: replace
  path: /metadata/name
  value: dev-ziggy-pod
EOF

# Create the kustomization file for prod environment
cat <<EOF > overlays/prod/kustomization.yaml
resources:
  - "../../manifest/"
patches:
  - path: ./patch-deploy.yaml
    target:
      kind: Deployment
  - path: ./patch-service.yaml
    target:
      kind: Service
  - path: ./patch-pod.yaml
    target:
      kind: Pod
EOF

# Create the patch files for prod environment
cat <<EOF > overlays/prod/patch-deploy.yaml
- op: replace
  path: /metadata/name
  value: prod-ziggy-deployment
- op: add
  path: /spec/template/spec/containers/0/resources
  value:
    limits:
      cpu: "3.0"
      memory: "2Gi"
    requests:
      cpu: "1.0"
      memory: "1Gi"
EOF

cat <<EOF > overlays/prod/patch-service.yaml
- op: replace
  path: /metadata/name
  value: prod-ziggy-service
EOF

cat <<EOF > overlays/prod/patch-pod.yaml
- op: replace
  path: /metadata/name
  value: prod-ziggy-pod
EOF

# Generate the final manifests for dev and prod environments
mkdir -p result
kustomize build overlays/dev > result/dev-result.yaml
kustomize build overlays/prod > result/prod-result.yaml
