# GitOps Lab: Managing Deployments with ArgoCD on OpenShift

Welcome to the GitOps lab! In this lab, you will learn how to manage Helm charts, Kustomize overlays, and ArgoCD application manifests for deploying microservices using ArgoCD on OpenShift. The `add-new-chart.sh` script automates the creation of these resources.

## Table of Contents

- [GitOps Lab: Managing Deployments with ArgoCD on OpenShift](#gitops-lab-managing-deployments-with-argocd-on-openshift)
  - [Table of Contents](#table-of-contents)
  - [Lab Overview](#lab-overview)
  - [Prerequisites](#prerequisites)
  - [Lab Setup](#lab-setup)
    - [Exercise 1: Clone the Repository](#exercise-1-clone-the-repository)
    - [Exercise 2: Initialize the Environment](#exercise-2-initialize-the-environment)
    - [Exercise 3: Validate ArgoCD is installed](#exercise-3-validate-argocd-is-installed)
    - [Exercise 4: Access ArgoCD UI](#exercise-4-access-argocd-ui)
  - [Lab Exercises](#lab-exercises)
    - [Exercise 5: Create Helm Charts and Kustomize Overlays](#exercise-5-create-helm-charts-and-kustomize-overlays)
    - [Exercise 6: Deploy ArgoCD Applications](#exercise-6-deploy-argocd-applications)
    - [Exercise 7: Sync ArgoCD Applications](#exercise-7-sync-argocd-applications)
    - [Exercise 8: Validate the Generated Charts and Manifests](#exercise-8-validate-the-generated-charts-and-manifests)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues](#common-issues)
    - [Debugging Tips](#debugging-tips)
  - [Conclusion](#conclusion)

## Lab Overview

In this lab, you will:
- Clone the repository containing the scripts and configurations.
- Initialize the environment.
- Install ArgoCD in OpenShift.
- Access the ArgoCD UI.
- Create Helm charts, Kustomize overlays, and ArgoCD application manifests.
- Deploy and sync ArgoCD applications.
- Validate the generated charts and manifests.

## Prerequisites

Before you begin, ensure you have the following tools installed:

- [Helm](https://helm.sh/docs/intro/install/)
- [Kustomize](https://kustomize.io/)
- [OpenShift CLI (oc)](https://docs.openshift.com/container-platform/4.16/cli_reference/openshift_cli/getting-started-cli.html)
- [ArgoCD CLI](https://argoproj.github.io/argo-cd/cli_installation/)

## Lab Setup

### Exercise 1: Clone the Repository

1. Open a terminal.
2. Clone the repository:
   ```bash
   git clone https://github.com/tosin2013/quarkus-helm-kustomize-example.git
   cd quarkus-helm-kustomize-example
   ```

### Exercise 2: Initialize the Environment

1. Run the initialization script:
   ```bash
   ./scripts/deploy.sh
   ```

### Exercise 3: Validate ArgoCD is installed

![20241005134919](https://i.imgur.com/shtYyMy.png)



### Exercise 4: Access ArgoCD UI
![20241005134945](https://i.imgur.com/NpXrqra.png)
![20241005135033](https://i.imgur.com/bM3vct4.png)
![20241005135116](https://i.imgur.com/g8ewVcl.jpeg)
![20241005135158](https://i.imgur.com/FgVjpf1.png)

## Lab Exercises

### Exercise 5: Create Helm Charts and Kustomize Overlays

1. Run the `add-new-chart.sh` script:
   ```bash
   ./add-new-chart.sh
   ```
   This script will:
   - Create Helm charts for each microservice in the `kustomize/base` directory.
   - Generate Kustomize overlays for each environment in the `kustomize/overlays` directory.
   - Build Kustomize manifests and save them in the `result` directory.
   - Create ArgoCD application manifests in the `result/apps` directory.

### Exercise 6: Deploy ArgoCD Applications

1. Test the application 
```bash
kustomize build kustomize/overlays/dev/microservice1
kustomize build kustomize/overlays/dev/microservice2
kustomize build kustomize/overlays/qa/microservice1
kustomize build kustomize/overlays/qa/microservice2
kustomize build kustomize/overlays/prod/microservice1
kustomize build kustomize/overlays/prod/microservice2
```
2. Deploy the ArgoCD applications:
```bash
kustomize build kustomize/overlays/dev/microservice1 | oc apply -f -
kustomize build kustomize/overlays/dev/microservice2 | oc apply -f -
kustomize build kustomize/overlays/qa/microservice1 | oc apply -f -
kustomize build kustomize/overlays/qa/microservice2 | oc apply -f -
kustomize build kustomize/overlays/prod/microservice1 | oc apply -f -
kustomize build kustomize/overlays/prod/microservice2 | oc apply -f -
```

### Exercise 7: Sync ArgoCD Applications

1. Sync the ArgoCD applications:
   ```bash
   argocd app sync -l app.kubernetes.io/instance=your-app-name
   ```

### Exercise 8: Validate the Generated Charts and Manifests

1. Validate the generated charts and manifests:
   ```bash
   ./validate-gitops.sh
   ```
   This script will:
   - Iterate over all directories in the `result` directory.
   - Validate each chart using custom validation commands (you can add your validation logic in the script).

## Troubleshooting

### Common Issues

1. **Helm Chart Creation Fails**:
   - Ensure Helm is installed and properly configured.
   - Check if the `kustomize/base` directory already exists and contains Helm charts.

2. **Kustomize Build Fails**:
   - Ensure Kustomize is installed and properly configured.
   - Check the `kustomize/overlays` directory for correct configurations.

3. **ArgoCD Application Creation Fails**:
   - Ensure ArgoCD is installed and properly configured in OpenShift.
   - Check the `result/apps` directory for correct ArgoCD application manifests.

### Debugging Tips

- Use the `-v` flag with `helm` and `kustomize` commands for verbose output.
- Check the ArgoCD logs for any errors:
  ```bash
  oc logs -n argocd -l app.kubernetes.io/name=argocd-server
  ```

## Conclusion

Congratulations! You have successfully completed the GitOps lab. You have learned how to manage deployments using Helm, Kustomize, and ArgoCD on OpenShift. By following the instructions, you have automated the creation of Helm charts, Kustomize overlays, and ArgoCD application manifests, ensuring a streamlined deployment process.
