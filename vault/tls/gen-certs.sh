#!/usr/bin/env bash
# Creates a private CA (once) and a 90-day TLS server certificate for Vault,
# then stores them as the Kubernetes secret "vault-tls" in the vault namespace.
# Private keys are written OUTSIDE the repo, to ~/.polaris/vault-tls (mode 700).
# Re-run to issue a new server certificate (rotation); the CA is reused.
set -euo pipefail

OUT="${HOME}/.polaris/vault-tls"
NS="vault"
CA_DAYS=365
CERT_DAYS=90

mkdir -p "$OUT" && chmod 700 "$OUT"
cd "$OUT"

echo "==> 1/3 Private CA (created once)"
if [[ ! -f ca.key ]]; then
  openssl ecparam -name prime256v1 -genkey -noout -out ca.key
  openssl req -x509 -new -key ca.key -sha256 -days "$CA_DAYS" \
    -subj "/CN=Polaris Vault CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -out ca.crt
fi

echo "==> 2/3 Vault server certificate (${CERT_DAYS} days)"
openssl ecparam -name prime256v1 -genkey -noout -out vault.key
openssl req -new -key vault.key -subj "/CN=vault.vault.svc" -out vault.csr
cat > vault.ext <<'EOF'
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectAltName=DNS:vault,DNS:vault.vault,DNS:vault.vault.svc,DNS:vault.vault.svc.cluster.local,DNS:vault-active.vault.svc,DNS:*.vault-internal,DNS:*.vault-internal.vault.svc.cluster.local,DNS:localhost,IP:127.0.0.1
EOF
openssl x509 -req -in vault.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days "$CERT_DAYS" -sha256 -extfile vault.ext -out vault.crt
chmod 600 ./*.key
openssl verify -CAfile ca.crt vault.crt

echo "==> 3/3 Kubernetes secret ${NS}/vault-tls"
kubectl -n "$NS" create secret generic vault-tls \
  --from-file=tls.crt=vault.crt --from-file=tls.key=vault.key --from-file=ca.crt=ca.crt \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Summary"
openssl x509 -in vault.crt -noout -subject -issuer -enddate
