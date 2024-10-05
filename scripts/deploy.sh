#!/bin/bash

# Check if logged in to OpenShift
if ! oc whoami &> /dev/null; then
    echo "Not logged in to OpenShift. Exiting..."
    exit 1
fi

oc create namespace openshift-gitops
oc create -k scripts/openshift-gitops
sleep 30s
oc apply -k scripts/openshift-gitops

