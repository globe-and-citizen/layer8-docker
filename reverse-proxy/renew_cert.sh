#!/bin/sh
set -e

echo "Waiting for step-ca..."

until nc -z step-ca 9000; do
  sleep 2
done

echo "Downloading root CA..."

curl -k ${CA_URL}/roots.pem -o ${ROOT_PATH}

echo "Ensuring server certificate exists..."

if [ ! -f ${CERT_PATH} ]; then
  echo "Requesting server certificate..."

  SAN_ARGS=""
  for san in $SANS; do
    SAN_ARGS="$SAN_ARGS --san $san"
  done

  step ca certificate \
    ${CERT_NAME} \
    ${CERT_PATH} \
    ${KEY_PATH} \
    $SAN_ARGS \
    --ca-url ${CA_URL} \
    --root ${ROOT_PATH} \
    --provisioner acme
fi

echo "Starting renewal daemon..."

exec step ca renew \
  ${CERT_PATH} \
  ${KEY_PATH} \
  --ca-url ${CA_URL} \
  --root ${ROOT_PATH} \
  --daemon
