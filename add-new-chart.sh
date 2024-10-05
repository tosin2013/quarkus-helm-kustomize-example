#!/bin/bash

# Prompt for the OpenShift entry point
read -p "Enter the OpenShift entry point (e.g., apps.ocp4.example.com): " ocp_entry_point

# Prompt for the Git repository URL
read -p "Enter the Git repository URL for ArgoCD applications: " git_repo_url

# Array of microservices
microservices=("microservice1" "microservice2")

# Array of environments
environments=("dev" "prod" "qa")

# Arrays of routes and namespaces for each environment
routes=("dev.$ocp_entry_point" "prod.$ocp_entry_point" "qa.$ocp_entry_point")
namespaces=("dev-namespace" "prod-namespace" "qa-namespace")

# Step 1: Create Helm charts for each microservice in base directory
create_helm_charts() {
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
}

# Step 2: Clean up Helm charts by keeping only necessary templates (deployment)
clean_helm_charts() {
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
}

# Step 3: Generate Helm output using helm template for each microservice into base directory
generate_helm_output() {
    for service in "${microservices[@]}"; do
        echo "Generating Helm output for $service"
        helm template $service kustomize/base/$service/helm > kustomize/base/$service/backend.yaml
    done
}

# Step 4: Add service configuration to kustomization.yaml for each microservice
add_service_configuration() {
    for service in "${microservices[@]}"; do
        echo "Creating base kustomization.yaml for $service"
        cat <<EOF > kustomize/base/$service/kustomization.yaml
resources:
  - backend.yaml
EOF
    done
}

# Step 5: Create overlay layers
create_overlay_layers() {
    for idx in "${!environments[@]}"; do
        env=${environments[$idx]}
        route=${routes[$idx]}
        namespace=${namespaces[$idx]}
        for service in "${microservices[@]}"; do
            echo "Setting up $env overlay for $service"
            mkdir -p kustomize/overlays/$env/$service

            # Create kustomization.yaml
            cat <<EOF > kustomize/overlays/$env/$service/kustomization.yaml
resources:
  - ../../../base/$service
  - route.yaml
  - namespace.yaml
patchesStrategicMerge:
  - patch-deployment.yaml
EOF

            # Generate deployment patch
            cat <<EOF > kustomize/overlays/$env/$service/patch-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
spec:
  replicas: 2
EOF

            # Add route.yaml
            cat <<EOF > kustomize/overlays/$env/$service/route.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: $service
spec:
  to:
    kind: Service
    name: $service
  host: $service-$env.$ocp_entry_point
  port:
    targetPort: 80
EOF

            # Add namespace.yaml
            cat <<EOF > kustomize/overlays/$env/$service/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
EOF

        done
    done
}

# Step 6: Build Kustomize manifests for each environment and microservice
build_kustomize_manifests() {
    for idx in "${!environments[@]}"; do
        env=${environments[$idx]}
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
}

# Step 7: Create ArgoCD application manifests
create_argocd_application_manifests() {
    for idx in "${!environments[@]}"; do
        env=${environments[$idx]}
        namespace=${namespaces[$idx]}
        for service in "${microservices[@]}"; do
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
    repoURL: $git_repo_url
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
        done
    done
}

main() {
    create_helm_charts
    clean_helm_charts
    generate_helm_output
    add_service_configuration
    create_overlay_layers
    build_kustomize_manifests
    create_argocd_application_manifests
}

main
