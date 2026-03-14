#!/bin/sh
set -e

echo "Waiting for step-ca..."

until nc -z step-ca 9000; do
  sleep 2
done

echo "step-ca is ready"

step ca bootstrap \
  --ca-url $CA_URL \
  --fingerprint $(step certificate fingerprint $ROOT_PATH)

echo "Ensuring client certificate exists..."

until [ -f "$CERT_PATH" ]; do
  echo "Requesting client certificate..."
  step ca certificate forward-proxy $CERT_PATH $KEY_PATH \
    --ca-url $CA_URL \
    --root $ROOT_PATH \
    --provisioner acme || true

  sleep 5
done

echo "Certificate obtained"

echo "Starting automatic renewal daemon..."

exec step ca renew $CERT_PATH $KEY_PATH \
  --ca-url $CA_URL \
  --root $ROOT_PATH \
  --daemon
