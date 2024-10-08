# Repository Directory Structure Logic

This document explains the purpose and logic behind the directory structure of this repository. It is intended to help new users understand how the repository is organized and how different components interact.

## Directory Structure

```
tree kustomize                                                                                       08:40:33 AM
kustomize
├── base
│   ├── microservice1
│   │   ├── backend.yaml
│   │   ├── helm
│   │   │   ├── Chart.yaml
│   │   │   ├── templates
│   │   │   │   ├── _helpers.tpl
│   │   │   │   ├── deployment.yaml
│   │   │   │   └── service.yaml
│   │   │   └── values.yaml
│   │   └── kustomization.yaml
│   └── microservice2
│       ├── backend.yaml
│       ├── helm
│       │   ├── Chart.yaml
│       │   ├── templates
│       │   │   ├── _helpers.tpl
│       │   │   ├── deployment.yaml
│       │   │   └── service.yaml
│       │   └── values.yaml
│       └── kustomization.yaml
└── overlays
    ├── dev
    │   ├── microservice1
    │   │   ├── kustomization.yaml
    │   │   ├── namespace.yaml
    │   │   ├── patch-deployment.yaml
    │   │   ├── patch-service.yaml
    │   │   └── route.yaml
    │   └── microservice2
    │       ├── kustomization.yaml
    │       ├── namespace.yaml
    │       ├── patch-deployment.yaml
    │       ├── patch-service.yaml
    │       └── route.yaml
    ├── prod
    │   ├── microservice1
    │   │   ├── kustomization.yaml
    │   │   ├── namespace.yaml
    │   │   ├── patch-deployment.yaml
    │   │   ├── patch-service.yaml
    │   │   └── route.yaml
    │   └── microservice2
    │       ├── kustomization.yaml
    │       ├── namespace.yaml
    │       ├── patch-deployment.yaml
    │       ├── patch-service.yaml
    │       └── route.yaml
    └── qa
        ├── microservice1
        │   ├── kustomization.yaml
        │   ├── namespace.yaml
        │   ├── patch-deployment.yaml
        │   ├── patch-service.yaml
        │   └── route.yaml
        └── microservice2
            ├── kustomization.yaml
            ├── namespace.yaml
            ├── patch-deployment.yaml
            ├── patch-service.yaml
            └── route.yaml

18 directories, 44 files
```


### kustomize

The `kustomize` directory is the root for all Kustomize-related configurations. It is divided into two main subdirectories: `base` and `overlays`.

#### base

The `base` directory contains the foundational configurations for each microservice. Each microservice has its own subdirectory within `base`.

- **microservice1** and **microservice2**: These directories contain the Helm charts and Kustomize configurations for each microservice.
  - **backend.yaml**: This file is generated by Helm and contains the Kubernetes manifests for the microservice.
  - **helm**: This directory contains the Helm chart for the microservice.
    - **Chart.yaml**: Metadata for the Helm chart.
    - **templates**: This directory contains the Helm templates.
      - **_helpers.tpl**: Helper templates for the Helm chart.
      - **deployment.yaml**: Deployment template for the microservice.
      - **service.yaml**: Service template for the microservice.
    - **values.yaml**: Values file for the Helm chart.
  - **kustomization.yaml**: Kustomize configuration file for the microservice.

#### overlays

The `overlays` directory contains environment-specific configurations for each microservice. Each environment (dev, prod, qa) has its own subdirectory within `overlays`.

- **dev**, **prod**, **qa**: These directories contain the environment-specific configurations for each microservice.
  - **microservice1** and **microservice2**: These directories contain the Kustomize overlays for each microservice in the respective environment.
    - **kustomization.yaml**: Kustomize configuration file for the microservice in the specific environment.
    - **namespace.yaml**: Kubernetes Namespace configuration for the microservice in the specific environment.
    - **patch-deployment.yaml**: Patch file for the Deployment resource in the specific environment.
    - **patch-service.yaml**: Patch file for the Service resource in the specific environment.
    - **route.yaml**: OpenShift Route configuration for the microservice in the specific environment.

### Purpose and Logic

- **Base Directory**: The `base` directory is used to store the common, environment-agnostic configurations for each microservice. This includes Helm charts and Kustomize configurations that are shared across all environments.

- **Overlays Directory**: The `overlays` directory is used to store environment-specific configurations. Each environment has its own subdirectory, and within each environment, there are subdirectories for each microservice. These subdirectories contain Kustomize overlays that modify the base configurations to suit the specific needs of the environment.

- **Helm Charts**: Helm charts are used to generate Kubernetes manifests for each microservice. The Helm templates in the `base` directory are environment-agnostic, while the values in `values.yaml` can be overridden in the overlays if necessary.

- **Kustomize**: Kustomize is used to manage and apply environment-specific configurations. The `kustomization.yaml` files in both `base` and `overlays` directories define how the configurations should be applied and merged.

- **Patches**: Patch files are used to modify the base configurations for each environment. For example, the `patch-deployment.yaml` file might increase the number of replicas for a microservice in the production environment.

- **Routes and Namespaces**: The `route.yaml` and `namespace.yaml` files define the OpenShift Route and Kubernetes Namespace for each microservice in each environment.

This structure allows for a clear separation of concerns between common configurations and environment-specific configurations, making it easier to manage and deploy microservices across different environments.
