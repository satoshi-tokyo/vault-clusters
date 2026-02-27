#!/bin/sh
engine=unified
VAULT_ADDR="http://127.0.0.1:8200"

vault secrets enable -path "pki-$engine" pki

vault secrets tune -max-lease-ttl=87600h "pki-$engine"

vault write -field=certificate "pki-$engine/root/generate/internal" \
  common_name="$engine.example.com" \
  issuer_name="$engine-root-2026" \
  ttl=87600h > "$engine-root-2026-ca.crt"

vault write "pki-$engine/roles/$engine-2026-servers" allow_any_name=true no_store=false

vault write pki-$engine/config/urls \
  issuing_certificates="$VAULT_ADDR/v1/pki-$engine/ca" \
  crl_distribution_points="$VAULT_ADDR/v1/pki-$engine/crl"

vault secrets enable -path=pki-int-$engine pki

vault secrets tune -max-lease-ttl=43800h "pki-int-$engine"

vault write -field=csr "pki-int-$engine/intermediate/generate/internal" \
  common_name="$engine.example.com" \
  issuer_name="$engine-example-dot-com-intermediate" \
  > "pki-int-$engine.csr"

vault write -field=certificate pki-$engine/root/sign-intermediate \
  issuer_ref="$engine-root-2026" \
  csr=@pki-int-$engine.csr \
  format=pem_bundle ttl="43800h" \
  > "pki-int-$engine.cert.pem"

vault write "pki-int-$engine/intermediate/set-signed" \
  certificate=@"pki-int-$engine.cert.pem"

vault write pki-int-$engine/roles/$engine-example-dot-com \
  issuer_ref="$(vault read -field=default pki-int-$engine/config/issuers)" \
  allowed_domains="$engine.example.com" \
  allow_subdomains=true \
  max_ttl="770h" \
  no_store=false

vault write pki-int-$engine/config/cluster \
  path="${VAULT_ADDR}/v1/pki-int-$engine" \
  aia_path="${VAULT_ADDR}/v1/pki-int-$engine"

vault write pki-int-$engine/config/urls \
  issuing_certificates='{{cluster_aia_path}}/issuer' \
  crl_distribution_points='{{cluster_aia_path}}/crl' \
  ocsp_servers='{{cluster_aia_path}}/ocsp' \
  enable_templating=true

vault write pki-int-$engine/config/crl \
    auto_rebuild=true \
    unified_crl=true \
    unified_crl_on_existing_paths=true

vault secrets tune \
    -passthrough-request-headers=If-Modified-Since \
    -allowed-response-headers=Last-Modified \
    -allowed-response-headers=Location \
    -allowed-response-headers=Replay-Nonce \
    -allowed-response-headers=Link \
    pki-int-$engine

vault write pki-int-$engine/config/acme enabled=true
