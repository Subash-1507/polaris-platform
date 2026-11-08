# Runbook: Jenkins VM SSH access

**Applies to:** `vm-polaris-jenkins` in `rg-polaris-devops`

## Symptom A: `ssh` hangs, then `Connection timed out`

**Likely cause:** your public IP changed (codespace restarted), so the NSG rule no longer matches.

```bash
source infra/env.sh && echo "$TF_VAR_admin_source_cidr"
cd infra/terraform
terraform plan -out=tfplan    # expect: 1 to change (nsg-polaris-jenkins source_address_prefix)
terraform apply tfplan
```

Also check the VM is running (auto-shutdown at 23:00 IST):
`az vm get-instance-view -g rg-polaris-devops -n vm-polaris-jenkins --query "instanceView.statuses[1].displayStatus" -o tsv`

## Symptom B: `Permission denied (publickey)`

**Likely cause:** the private key `~/.ssh/polaris-jenkins` was lost (codespace rebuilt or deleted).
No VM rebuild is needed; Terraform ignores `admin_ssh_key` changes.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/polaris-jenkins -C "polaris-jenkins" -N ""
az vm user update -g rg-polaris-devops -n vm-polaris-jenkins \
  --username azureuser --ssh-key-value "$(cat ~/.ssh/polaris-jenkins.pub)"
cp ~/.ssh/polaris-jenkins.pub infra/ssh/polaris-jenkins.pub
git add infra/ssh/polaris-jenkins.pub && git commit -m "chore(infra): rotate Jenkins VM SSH key"
```

Verify: `ssh -i ~/.ssh/polaris-jenkins azureuser@$(terraform -chdir=infra/terraform output -raw jenkins_public_ip) hostname`

The old key stays in `authorized_keys`; remove its line on the VM after you confirm the new key works.

## Break-glass (no SSH at all)

Run a command through the Azure control plane; no network path to port 22 needed:

```bash
az vm run-command invoke -g rg-polaris-devops -n vm-polaris-jenkins \
  --command-id RunShellScript --scripts "systemctl status ssh --no-pager | head -5"
```

The serial console is also available (boot diagnostics are enabled) in the Azure portal.
