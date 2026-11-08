#!/usr/bin/env bash
# Bootstrap: Azure Storage for Terraform remote state.
# Terraform cannot create the storage that holds its own state, so this one piece
# is created with the Azure CLI. Safe to re-run (idempotent).
set -euo pipefail

source "$(dirname "$0")/env.sh"

echo ">> Resource group: $TFSTATE_RG"
az group create --name "$TFSTATE_RG" --location "$LOCATION" --tags $TAGS -o none

echo ">> Storage account: $TFSTATE_SA"
az storage account create \
  --name "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --tags $TAGS \
  -o none

echo ">> Blob versioning + 7-day soft delete (protects state from corruption/deletion)"
az storage account blob-service-properties update \
  --account-name "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  -o none

echo ">> Container: $TFSTATE_CONTAINER"
EXISTS=$(az storage container-rm exists --storage-account "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" --name "$TFSTATE_CONTAINER" --query exists -o tsv)
if [ "$EXISTS" != "true" ]; then
  az storage container-rm create --storage-account "$TFSTATE_SA" \
    --resource-group "$TFSTATE_RG" --name "$TFSTATE_CONTAINER" -o none
fi

echo ">> Data access for you: Storage Blob Data Contributor on the state account"
ME=$(az ad signed-in-user show --query id -o tsv)
SA_ID=$(az storage account show --name "$TFSTATE_SA" --resource-group "$TFSTATE_RG" --query id -o tsv)
HAS_ROLE=$(az role assignment list --assignee "$ME" --role "Storage Blob Data Contributor" \
  --scope "$SA_ID" --query "[0].id" -o tsv)
if [ -z "$HAS_ROLE" ]; then
  az role assignment create --assignee-object-id "$ME" --assignee-principal-type User \
    --role "Storage Blob Data Contributor" --scope "$SA_ID" -o none
fi

echo "Done: state goes to $TFSTATE_SA/$TFSTATE_CONTAINER (resource group $TFSTATE_RG)"
