#!/bin/bash

# Array of microservices
microservices=("microservice1" "microservice2")

# Array of environments
environments=("dev" "prod" "qa")

# Step 1: Create Helm charts for each microservice in base directory
for service in "${microservices[@]}"; do
    echo "Creating Helm chart for $service"
    mkdir -p kustomize/base/$service/helm
    helm create kustomize/base/$service/helm
done

# Step 2: Clean up Helm charts by keeping only necessary templates (deployment, service, pod)
for service in "${microservices[@]}"; do
    echo "Cleaning up Helm templates for $service"
    rm -rf kustomize/base/$service/helm/templates/*
    # Generate new basic templates
    cat <<EOF > kustomize/base/$service/helm/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.name }}
    spec:
      containers:
      - name: {{ .Values.name }}
        image: {{ .Values.image }}
        ports:
        - containerPort: 80
EOF
done

# Step 3: Generate Helm output using helm template for each microservice into base directory
for service in "${microservices[@]}"; do
    echo "Generating Helm output for $service"
    helm template $service kustomize/base/$service/helm > kustomize/base/$service/backend.yaml
done

# Step 4: Set up base kustomization.yaml for each microservice
for service in "${microservices[@]}"; do
    echo "Creating base kustomization.yaml for $service"
    cat <<EOF > kustomize/base/$service/kustomization.yaml
resources:
  - backend.yaml
EOF
done

# Step 5: Create directories for dev, prod, qa overlays and configure kustomization.yaml and patches
for env in "${environments[@]}"; do
    for service in "${microservices[@]}"; do
        echo "Setting up $env overlay for $service"
        mkdir -p kustomize/overlays/$env/$service
        cat <<EOF > kustomize/overlays/$env/$service/kustomization.yaml
resources:
  - ../../../base/$service
patches:
  - path: values-$env.yaml
    target:
      kind: Deployment
EOF

        # Generate values overrides for each environment
        cat <<EOF > kustomize/overlays/$env/$service/values-$env.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service-$env
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: $service
        image: nginx:1.16.0
EOF
    done
done

# Step 6: Build Kustomize manifests for each environment and microservice
for env in "${environments[@]}"; do
    for service in "${microservices[@]}"; do
        echo "Building Kustomize manifests for $service in $env environment"
        mkdir -p result/$env
        kustomize build kustomize/overlays/$env/$service > result/$env/$service.yaml

        # Check if the build was successful
        if [[ $? -eq 0 ]]; then
            echo "$env/$service build succeeded!"
        else
            echo "$env/$service build failed."
        fi
    done
done

echo "All Kustomize builds complete!"
