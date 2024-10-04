#!/bin/bash

# Create the main directory structure
mkdir -p kustomize/base/microservice1/helm
mkdir -p kustomize/base/microservice1
mkdir -p kustomize/base/microservice2/helm
mkdir -p kustomize/base/microservice2
mkdir -p kustomize/overlays/dev/app
mkdir -p kustomize/overlays/dev/microservice1
mkdir -p kustomize/overlays/dev/microservice2

# Create the necessary files
touch kustomize/base/microservice1/helm/Chart.yaml
touch kustomize/base/microservice1/helm/values.yaml
touch kustomize/base/microservice1/kustomization.yaml

touch kustomize/base/microservice2/helm/Chart.yaml
touch kustomize/base/microservice2/helm/values.yaml
touch kustomize/base/microservice2/kustomization.yaml

touch kustomize/overlays/dev/app/kustomization.yaml
touch kustomize/overlays/dev/microservice1/values-dev.yaml
touch kustomize/overlays/dev/microservice1/kustomization.yaml

touch kustomize/overlays/dev/microservice2/values-dev.yaml
touch kustomize/overlays/dev/microservice2/kustomization.yaml
