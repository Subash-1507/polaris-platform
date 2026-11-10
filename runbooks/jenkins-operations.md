# Runbook: Jenkins operations

**Applies to:** Jenkins controller and agent on `vm-polaris-jenkins`
(`/opt/polaris/polaris-platform/jenkins`). VM commands run as `azureuser` with `sudo`.

## Open the UI

From the codespace (keep this terminal open):

```bash
ssh -i ~/.ssh/polaris-jenkins -N -L 8080:127.0.0.1:8080 azureuser@$(terraform -chdir=infra/terraform output -raw jenkins_public_ip)
```

Open port 8080 from the Codespaces **Ports** tab. Keep visibility **Private**.
SSH times out? See [Jenkins VM SSH access](jenkins-vm-ssh-access.md), Symptom A.

## Deploy a change (after merging to main)

1. Pull and rebuild (recreates containers only if an image or `docker-compose.yml` changed):

```bash
cd /opt/polaris/polaris-platform && sudo git pull && cd jenkins && sudo docker compose up -d --build
```

2. Check:

```bash
sudo docker compose ps --format '{{.Name}}: {{.Image}} {{.Status}}'
sudo docker compose logs controller 2>&1 | grep -iE "SEVERE|ConfiguratorException" | head -5
```

3. **If `jenkins/casc/` changed, restart the controller.** JCasC reads its files only at startup,
   and Compose does not restart a container when only a bind-mounted file changes:

```bash
sudo docker compose restart controller
timeout 240 bash -c 'until sudo docker compose logs --since 2m controller 2>&1 | grep -q "fully up and running"; do sleep 5; done' && echo READY
```

Healthy result: both containers show **tag names** (not `sha256:`), the controller is
`(healthy)`, no SEVERE lines, and `docker compose logs agent` ends with `INFO: Connected`.

## Symptom: agent offline / builds stuck "waiting for next available executor"

1. `sudo docker compose ps`: is `jenkins-agent` running? If not: `sudo docker compose up -d agent`.
2. `sudo docker compose logs --tail 50 agent`: look for `Connected` or an exception.
3. Secret rejected (for example after `/srv/jenkins_home` was rebuilt): re-fetch it.

```bash
PW=$(sudo cat /opt/polaris/secrets/jenkins_admin_password) && curl -sf -u "admin:$PW" http://127.0.0.1:8080/computer/docker-agent/jenkins-agent.jnlp | grep -oE '[a-f0-9]{64}' | head -1 | tr -d '\n' | sudo tee /opt/polaris/secrets/jenkins_agent_secret >/dev/null; unset PW
sudo docker compose up -d --force-recreate agent
```

## Rotate the admin password

JCasC resets the password from the secret file at every start.

```bash
tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 | sudo tee /opt/polaris/secrets/jenkins_admin_password >/dev/null
sudo docker compose restart controller
sudo cat /opt/polaris/secrets/jenkins_admin_password; echo   # store it in the password manager
```

## Known issue (fixed): image tag drift

**Symptom:** `docker compose ps` shows `sha256:…` instead of a tag in IMAGE.
**Cause:** Docker 29 adds a provenance attestation to each build, so every rebuild got a new
image ID; running containers stayed on the old, untagged ID.
**Fix:** `provenance: false` on both builds in `docker-compose.yml`.
**Verify:** rebuild twice; `docker images 'polaris/*'` IDs do not change.

## Known issue (fixed): zombie processes on the agent

**Symptom:** login banner shows `There are N zombie processes`; N grows by 8 per smoke build.
**Cause:** the agent's `java` ran as PID 1 without an init, so it never reaped orphaned
`sh`, `git` and `az` (python3) processes left by pipeline steps.
**Fix:** `init: true` on the agent service (Docker's tini becomes PID 1).
**Check:**

```bash
echo "zombies: $(ps -eo stat | grep -c '^Z')"          # expect 0
sudo docker top jenkins-agent -o pid,ppid,comm         # first process: docker-init
```

## Known issue: JCasC change not applied after deploy

**Symptom:** after merging a change to `jenkins/casc/`, Jenkins still behaves as before
(for example, a job builds a deleted branch: "Couldn't find any revision to build").
**Cause:** side effect of the tag-drift fix. Rebuilds now keep the same image ID, so Compose
no longer recreates the controller, and JCasC is only read at startup.
**Fix:** step 3 of "Deploy a change": `sudo docker compose restart controller`.
**Check:** the job's live config shows the expected value:

```bash
PW=$(sudo cat /opt/polaris/secrets/jenkins_admin_password) && curl -sf -u "admin:$PW" http://127.0.0.1:8080/job/platform-smoke-test/config.xml | grep -oE '\*/[a-z0-9/-]+'; unset PW
```

## Start and stop

Containers use `restart: unless-stopped`: they start with the VM, so starting the VM is enough.
See the README **Cost control** section.
