# 0003: Run Jenkins in Docker on a VM, configured as code

- **Status:** Accepted
- **Date:** 2026-11-10

## Context

The platform needs CI/CD that builds images, pushes them to ACR and deploys to AKS.
Constraints: a 6-vCPU regional quota (one AKS node plus one small VM), a 4 GB VM,
no public exposure of Jenkins, and no cloud credentials stored in Jenkins.

## Decision

- **Topology:** one Jenkins controller and one build agent as Docker containers on
  `vm-polaris-jenkins`, managed by Docker Compose (`jenkins/docker-compose.yml`).
- **Everything as code:** controller image with baked-in plugins, Configuration as Code
  (`jenkins/casc/jenkins.yaml`) for security, nodes and jobs (Job DSL); no setup wizard,
  no UI-only configuration.
- **Pinned versions:** Jenkins `2.580.2` on JDK 25, agent base image pinned by digest,
  kubectl `v1.36.4` (matches AKS) and Helm `v4.1.4` verified by SHA-256.
- **Builds never run on the controller:** controller has 0 executors; one inbound agent
  connects over WebSocket on port 8080, so port 50000 stays closed.
- **No exposure:** the UI is bound to `127.0.0.1:8080` and reached through an SSH tunnel;
  the NSG allows only SSH from the admin IP.
- **No stored cloud credentials:** pipelines use the VM's managed identity
  (`az login --identity`) with `AcrPush` and `AKS Cluster User`; token caches live in the
  workspace and are wiped after every build.
- **Secrets:** the admin password and agent secret are Docker secret files in
  `/opt/polaris/secrets` on the VM (moving to Vault in Phase 3).
- **JDK 25 from day one:** Jenkins announced end of Java 21 support (Sep 2027); upgrading
  an empty server is cheaper than migrating a busy one.

## Alternatives considered

- **Jenkins on AKS (Helm chart):** competes with workloads for the single node, and the
  cluster is stopped when idle.
- **GitHub Actions:** simpler, but the target role uses Jenkins.
- **Rootless BuildKit or Kaniko instead of the Docker socket:** safer, more moving parts;
  revisit when builds move to Kubernetes agents.
- **Public Jenkins with TLS and SSO:** larger attack surface for a lab.

## Consequences and accepted risks

- **Docker socket in the agent is root-equivalent on the VM.** Accepted for a single-tenant
  lab: only this repository's pipelines run, the VM holds no credentials beyond its scoped
  managed identity, and it is isolated by the NSG.
- **Plugin versions are not pinned** (Jenkins core is); builds resolve the latest compatible
  plugins. Revisit with a plugin lock file.
- **GitHub webhooks cannot reach Jenkins** (not exposed); Phase 6 uses SCM polling or a relay.
- **"Reverse proxy is broken" notice** is expected: the Codespaces URL differs from the
  configured `http://localhost:8080/`.
- **Single VM, no backup yet** of `/srv/jenkins_home`; config is rebuildable from Git,
  build history is not. Backlog: snapshot or backup job.
- **Content Security Policy not yet enforced.** Backlog: enable, export with JCasC, commit.
- **Operational fixes found while building this:** build provenance disabled for these local
  images (stops tag drift), and the agent runs under `init` (stops zombie processes).
  See `runbooks/jenkins-operations.md`.
