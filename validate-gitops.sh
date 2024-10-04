#!/bin/bash

# Define the base directory where the charts are generated
BASE_DIR="result"

# Function to validate a chart
validate_chart() {
  local chart_dir=$1
  echo "Validating chart in directory: $chart_dir"
  # Validate Helm chart
  helm lint $chart_dir/helm
  helm template $chart_dir/helm > /tmp/rendered-chart.yaml
  kubeval /tmp/rendered-chart.yaml

  # Validate Kustomize manifest
  kustomize build $chart_dir > /tmp/rendered-kustomize.yaml
  kubeval /tmp/rendered-kustomize.yaml
}

# Iterate over all directories in the base directory
for dir in "$BASE_DIR"/*; do
  if [ -d "$dir" ]; then
    validate_chart "$dir"
  fi
done
