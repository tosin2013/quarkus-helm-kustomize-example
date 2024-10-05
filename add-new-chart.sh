#!/bin/bash

# Prompt for the OpenShift entry point
read -p "Enter the OpenShift entry point (e.g., apps.ocp4.example.com): " ocp_entry_point

# Array of microservices
microservices=("microservice1" "microservice2")

# Array of environments
environments=("dev" "prod" "qa")

# Array of routes for each environment
routes=("dev.$ocp_entry_point" "prod.$ocp_entry_point" "qa.$ocp_entry_point")

# Array of namespaces for each environment
namespaces=("dev-namespace" "prod-namespace" "qa-namespace")

# Step 1: Create Helm charts for each microservice in base directory
for service in "${microservices[@]}"; do
    echo "Creating Helm chart for $service"
    if [ ! -d "kustomize/base/$service/helm" ]; then
        mkdir -p kustomize/base/$service/helm
        helm create kustomize/base/$service/helm
    else
        echo "Directory kustomize/base/$service/helm already exists. Skipping helm create."
    fi

    # Update values.yaml to include the name field
    cat <<EOF > kustomize/base/$service/helm/values.yaml
name: $service
replicas: 1
image: nginx:1.16.0
EOF
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

        # Add route and namespace patches
        cat <<EOF > kustomize/overlays/$env/$service/route.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: $service-$env
spec:
  to:
    kind: Service
    name: $service-$env
  host: $route
  port:
    targetPort: 80
EOF

        cat <<EOF > kustomize/overlays/$env/$service/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
EOF

        # Update kustomization.yaml to include route and namespace
        cat <<EOF >> kustomize/overlays/$env/$service/kustomization.yaml
  - route.yaml
  - namespace.yaml
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

# Function to create ArgoCD application manifests
create_argocd_application() {
    local env=$1
    local service=$2
    local namespace=${namespaces[$i]}  # Use the correct namespace for each environment

    echo "Creating ArgoCD application manifest for $service in $env environment"
    mkdir -p result/apps/$env
    cat <<EOF > result/apps/$env/$service-argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $service-$env
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-repo/your-repo.git  # Replace with your repo URL
    targetRevision: HEAD
    path: kustomize/overlays/$env/$service
  destination:
    server: https://kubernetes.default.svc
    namespace: $namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
}

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

        # Create ArgoCD application manifest
        create_argocd_application $env $service ${namespaces[$i]}
    done
done

echo "All Kustomize builds complete!"
