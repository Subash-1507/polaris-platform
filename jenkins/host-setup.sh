#!/usr/bin/env bash
# Prepares vm-polaris-jenkins to run Jenkins in Docker. Idempotent: safe to re-run.
# Run from the codespace (repo root):
#   ssh -i ~/.ssh/polaris-jenkins azureuser@<vm-ip> 'sudo bash -s' < jenkins/host-setup.sh
set -euo pipefail
# No interactive prompts from apt/debconf/needrestart (this script is fed through stdin)
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a

echo "==> 1/4 Swap (4 GiB)"
if ! swapon --show | grep -q '^/swapfile'; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
fi
grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
# Prefer RAM; only swap under real memory pressure
echo 'vm.swappiness=10' > /etc/sysctl.d/99-polaris-swap.conf
sysctl -q -p /etc/sysctl.d/99-polaris-swap.conf

echo "==> 2/4 Docker Engine (official Docker apt repository)"
if ! command -v docker >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl git >/dev/null
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
fi
systemctl enable --now docker >/dev/null 2>&1

echo "==> 3/4 Docker log rotation"
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
systemctl restart docker

echo "==> 4/4 Directories"
install -d -m 0755 /opt/polaris
# The Jenkins container runs as uid/gid 1000
install -d -o 1000 -g 1000 -m 0750 /srv/jenkins_home

echo "==> Summary"
docker --version
docker compose version
swapon --show
free -h | sed -n '1,3p'
echo "unattended-upgrades: $(systemctl is-enabled unattended-upgrades 2>/dev/null || echo missing)"
