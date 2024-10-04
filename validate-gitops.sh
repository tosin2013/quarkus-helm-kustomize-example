#!/bin/bash

# Define the base directory where the charts are generated
BASE_DIR="result"

# Function to validate a chart
validate_chart() {
  local chart_dir=$1
  echo "Validating chart in directory: $chart_dir"
  # Add your validation commands here
  # Example: kubeval $chart_dir/*.yaml
}

# Iterate over all directories in the base directory
for dir in "$BASE_DIR"/*; do
  if [ -d "$dir" ]; then
    validate_chart "$dir"
  fi
done
