# 0002: Manage Azure infrastructure with Terraform and remote state

- **Status:** Accepted
- **Date:** 2026-11-08

## Context

The resource group and container registry were first created by hand with the Azure CLI.
Manual changes leave no review trail, drift silently, and cannot be rebuilt reliably
after a teardown, which matters because this lab is destroyed and recreated to save cost.

## Decision

- All Azure resources are defined in Terraform (`infra/terraform/`, azurerm provider `~> 4.0`).
- State lives in Azure Storage (`stpolaristf4827` / `tfstate`) in its own resource group,
  `rg-polaris-tfstate`, so destroying the platform never deletes the state.
- The state account uses Entra ID auth only (shared keys disabled), TLS 1.2, no public blob
  access, blob versioning and 7-day soft delete. Blob leases lock the state during runs.
- The CLI-created resource group and ACR were adopted with `import` blocks, verified by a
  plan showing `2 to import, 0 to change`.
- Every change is `plan -out` → review → `apply` of the saved plan.
- Layers stay separate: Terraform owns Azure resources; in-cluster objects live in
  `k8s/` and `helm/` and are applied by kubectl/Helm (later Jenkins).
- No secrets in code: the subscription ID and admin IP come from `TF_VAR_*` in `infra/env.sh`.

## Alternatives considered

- **Azure CLI scripts:** fast to start, but not declarative and no drift detection.
- **Bicep:** good Azure-native option; Terraform chosen because it is cloud-agnostic and
  widely used in the target role's tooling.
- **Local state:** lost if the codespace is deleted, and no locking.

## Consequences

- One more resource group and storage account to keep (cost: cents per month).
- Anyone running Terraform needs `Storage Blob Data Contributor` on the state account.
- `terraform apply` must not run while AKS is stopped; start the cluster first.
- Kubernetes upgrades are a one-line, reviewed change to `kubernetes_version`.
