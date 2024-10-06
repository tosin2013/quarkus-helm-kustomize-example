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
  host: $service-$env.$route
  port:
    targetPort: 80
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
