# 0001: Deploy to Southeast Asia on B-series v2 VMs

- **Status:** Accepted
- **Date:** 2026-11-07

## Context

- The subscription (Azure for Students) has an Azure Policy assignment, **Allowed locations**,
  that permits only: `austriaeast`, `malaysiawest`, `uaenorth`, `southeastasia`, `koreacentral`.
  The closest region to the team, `centralindia`, is not allowed.
- In `southeastasia`, `Standard_B2s` and `Standard_B2ms` are **NotAvailableForSubscription**.
  B-series v2 sizes (`B2as_v2`, `B2als_v2`, `B2s_v2`, `B2ls_v2`) are available except in
  availability zone 1. ARM-based "p" sizes are unrestricted.
- Regional vCPU quota is **6** in total (Basv2 and Bsv2 families: 10 each).
- The AKS workloads (Vault, Redis, PostgreSQL, Datadog Agent, gateway, API) need about 8 GB of memory.

## Decision

- **Region:** `southeastasia`: the most mature of the allowed regions, closest to the team,
  and co-located with Apigee in GCP `asia-southeast1`.
- **AKS node:** 1 × `Standard_B2as_v2` (2 vCPU, 8 GB, AMD x86-64).
- **Jenkins VM:** `Standard_B2als_v2` (2 vCPU, 4 GB, AMD x86-64).
- No availability-zone pinning (zone 1 is restricted; Azure places resources in an allowed zone).
- No ARM sizes, so every container image stays single-architecture (amd64).

## Consequences

- ✅ Uses 4 of 6 vCPUs; the AKS upgrade surge node fits exactly (6 of 6).
- ✅ Standard x86 images work everywhere; no multi-arch builds needed.
- ⚠️ No room for a second AKS node: a single node is a single point of failure, and node
  upgrades cause brief downtime. Acceptable for a lab; drills must account for it.
- ⚠️ A production deployment for a US-based client would run in a US region (for example East US 2)
  for latency and data-residency reasons.
- Fallbacks: region `koreacentral`; VM sizes `Standard_B2s_v2` / `Standard_B2ls_v2` (Intel).
