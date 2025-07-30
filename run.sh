#!/bin/bash

copy_env() {
  cp auth-server/.env.dev auth-server/.env
  cp forward-proxy/.env.dev forward-proxy/.env
  cp reverse-proxy/.env.dev reverse-proxy/.env
}

upload_cert() {
  # login to get token
  TOKEN=$(curl --silent --location 'http://localhost:5001/api/v1/login-client' \
    --header 'Content-Type: application/json' \
    --data '{
      "password": "12341234",
      "username": "layer8"
  }' | jq -r '.token')

  echo "Token is: $TOKEN"

  RP_CERT=$(awk '{printf "%s\\n", $0}' "./reverse-proxy/ntor_cert.pem")
  echo "File content: $RP_CERT"

  curl --location 'http://localhost:5001/api/upload-certificate' \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $TOKEN" \
    --data "{
      \"certificate\": \"$RP_CERT\"
    }"
}

# main
if [ -z "$1" ]; then
  echo "Missing argument"
  exit 1
fi

if [ "$1" = "init" ]; then
  copy_env
  sleep 1
  docker compose up -d
  sleep 30
  upload_cert
elif [ "$1" = "start" ]; then
  docker compose up -d
elif [ "$1" = "upload" ]; then
  upload_cert
fi
