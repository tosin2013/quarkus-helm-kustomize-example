resources:
  - ../../../base/microservice1
  - route.yaml
  - namespace.yaml
patches:
  - path: patch-deployment.yaml
    target:
      kind: Deployment
      name: microservice1
  - path: patch-service.yaml
    target:
      kind: Service
      name: microservice1
