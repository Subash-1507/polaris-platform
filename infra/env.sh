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


# Terraform remote state: separate resource group, so `terraform destroy` never deletes it
export TFSTATE_RG="rg-polaris-tfstate"
export TFSTATE_SA="stpolaristf4827"
export TFSTATE_CONTAINER="tfstate"

# Terraform: subscription ID passed in as a variable (kept out of the code)
export TF_VAR_subscription_id="$(az account show --query id -o tsv 2>/dev/null || true)"
