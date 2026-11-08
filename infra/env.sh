#!/usr/bin/env bash
# Polaris platform: shared names and settings (NO secrets in this file)
# Load into your terminal with:  source infra/env.sh

export LOCATION="southeastasia"
export RG="rg-polaris-devops"
export TAGS="project=polaris env=lab"

# Container registry
export ACR_NAME="acrpolaris4827"

# AKS
export AKS_NAME="aks-polaris"
export AKS_NODE_SIZE="Standard_B2as_v2"

# Jenkins VM
export VM_NAME="vm-polaris-jenkins"
export VM_SIZE="Standard_B2als_v2"
export VM_USER="azureuser"
