#!/bin/bash
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x
set -euo pipefail

rm -rf kustomize result

# Prompt for the OpenShift entry point
read -rp "Enter the OpenShift entry point (e.g., apps.ocp4.example.com): " ocp_entry_point

# Prompt for the Git repository URL
read -rp "Enter the Git repository URL for ArgoCD applications: " git_repo_url

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
            mkdir -p "kustomize/base/$service/helm/templates"
            cat <<EOF > "kustomize/base/$service/helm/templates/_helpers.tpl"
{{- define "testme.fullname" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testme.labels" -}}
app: {{ .Values.name }}
{{- end -}}

{{- define "testme.selectorLabels" -}}
app: {{ .Values.name }}
{{- end -}}
EOF
        else
            echo "Directory kustomize/base/$service/helm already exists. Skipping helm create."
        fi

        # Update values.yaml to include the name field and custom field
        cat <<EOF > "kustomize/base/$service/helm/values.yaml"
name: $service
replicas: 1
image: nginx:1.27.2
service:
  type: ClusterIP
  port: 80
custom:
  title: "Custom Nginx Page"
  heading: "Welcome to My Custom Nginx Page!"
EOF

        # Add Chart.yaml
        cat <<EOF > "kustomize/base/$service/helm/Chart.yaml"
apiVersion: v2
name: $service
description: A Helm chart for Kubernetes
version: 0.1.0
appVersion: "1.0"
EOF

        # Add _helpers.tpl
        mkdir -p "kustomize/base/$service/helm/templates"
        cat <<EOF > "kustomize/base/$service/helm/templates/_helpers.tpl"
{{- define "testme.fullname" -}}
{{- .Values.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testme.labels" -}}
app: {{ .Values.name }}
{{- end -}}

{{- define "testme.selectorLabels" -}}
app: {{ .Values.name }}
{{- end -}}
EOF
    done
}

# Step 2: Clean up Helm charts by keeping only necessary templates (deployment)
clean_helm_charts() {
    for service in "${microservices[@]}"; do
        echo "Cleaning up Helm templates for $service"
        rm -rf "kustomize/base/$service/helm/templates/*"
        cat <<EOF > "kustomize/base/$service/helm/templates/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "testme.fullname" . }}
  labels:
    {{- include "testme.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      {{- include "testme.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "testme.labels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ .Values.name }}-sa
      containers:
      - name: {{ .Values.name }}
        image: {{ .Values.image }}
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html-volume
        configMap:
          name: {{ .Values.name }}-html
EOF

        cat <<EOF > "kustomize/base/$service/helm/templates/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: {{ include "testme.fullname" . }}
  labels:
    {{- include "testme.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
      protocol: TCP
      name: http
  selector:
    {{- include "testme.selectorLabels" . | nindent 4 }}
EOF

        cat <<EOF > "kustomize/base/$service/helm/templates/configmap.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.name }}-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>{{ .Values.custom.title | default "Custom Nginx Page" }}</title>
    </head>
    <body>
      <h1>{{ .Values.custom.heading | default "Welcome to My Custom Nginx Page!" }}</h1>
    </body>
    </html>
EOF
    done
}

# Step 3: Generate Helm output using helm template for each microservice into base directory
generate_helm_output() {
    for service in "${microservices[@]}"; do
        echo "Generating Helm output for $service"
        helm template "$service" "kustomize/base/$service/helm" > "kustomize/base/$service/backend.yaml"
    done
}

# Step 4: Add service configuration to kustomization.yaml for each microservice
add_service_configuration() {
    for service in "${microservices[@]}"; do
        echo "Creating base kustomization.yaml for $service"
        cat <<EOF > "kustomize/base/$service/kustomization.yaml"
resources:
  - backend.yaml
EOF
    done
}

# Step 5: Create overlay layers
create_overlay_layers() {
    for idx in "${!environments[@]}"; do
        env=${environments[$idx]}
        namespace=${namespaces[$idx]}
        route=${routes[$idx]}
        for service in "${microservices[@]}"; do
            echo "Setting up $env overlay for $service"
            mkdir -p "kustomize/overlays/$env/$service"

            # Create kustomization.yaml
            cat <<EOF > "kustomize/overlays/$env/$service/kustomization.yaml"
namespace: $namespace
resources:
  - ../../../base/$service
  - route.yaml
  - namespace.yaml
  - service-account.yaml
  - cluster-role.yaml
patches:
  - path: patch-deployment.yaml
    target:
      kind: Deployment
      name: $service
  - path: patch-service.yaml
    target:
      kind: Service
      name: $service
  - path: patch-configmap.yaml
    target:
      kind: ConfigMap
      name: $service-html
EOF

            # Generate deployment patch
            cat <<EOF > "kustomize/overlays/$env/$service/patch-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  namespace: $namespace
spec:
  replicas: 2
EOF

            # Generate service patch
            cat <<EOF > "kustomize/overlays/$env/$service/patch-service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: $service
  namespace: $namespace
spec:
  type: ClusterIP
EOF

            # Generate service patch
            cat <<EOF > "kustomize/overlays/$env/$service/patch-configmap.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: microservice1-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Custom $service Nginx Page</title>
    </head>
    <body>
      <h1>Welcome to My Custom $service Nginx Page!</h1>
    </body>
    </html>
EOF

            # Add route.yaml
            cat <<EOF > "kustomize/overlays/$env/$service/route.yaml"
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: $service
  namespace: $namespace
spec:
  to:
    kind: Service
    name: $service
    weight: 100
  host: $service-$env.$route
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: None
  wildcardPolicy: None
EOF

            # Add namespace.yaml
            cat <<EOF > "kustomize/overlays/$env/$service/namespace.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace
EOF

            # Add service-account.yaml
            cat <<EOF > "kustomize/overlays/$env/$service/service-account.yaml"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $service-sa
  namespace: $namespace
EOF

            # Add cluster-role.yaml
            cat <<EOF > "kustomize/overlays/$env/$service/cluster-role.yaml"
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: 'system:openshift:scc:anyuid'
  namespace: $namespace
subjects:
  - kind: ServiceAccount
    name: $service-sa
    namespace: $namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: 'system:openshift:scc:anyuid'
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
            mkdir -p "result/$env"
            kustomize build "kustomize/overlays/$env/$service" > "result/$env/$service.yaml"

            # Check if the build was successful
            if kustomize build "kustomize/overlays/$env/$service"; then
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
            mkdir -p "result/apps/$env"
            cat <<EOF > "result/apps/$env/$service-argocd-app.yaml"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $service-$env
  namespace: openshift-gitops
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
