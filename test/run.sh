#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="$1"
if [ "${2:-}" = "--build" ]; then
  BUILD_OPTION="--build"
else
  BUILD_OPTION=""
fi

wait_for_auth_server() {
  # Begin waiting for the auth-server to become available.
  echo "Waiting for auth-server..."

  # Continuously check the auth-server logs until the startup line appears.
  # Redirect stderr to stdout so grep sees all output from docker compose.
  until docker compose -f "$COMPOSE_FILE" logs auth-server 2>&1 | \
    # Search for the exact server startup message indicating readiness.
    grep -q "Server start at: http://0.0.0.0:5001"
  do
    # Message not found yet — pause briefly before the next attempt.
    sleep 1
  done

  # Loop exited: auth-server reported it started successfully.
  echo "auth-server is ready"
}

docker compose -f "$COMPOSE_FILE" up -d ${BUILD_OPTION:+$BUILD_OPTION}

wait_for_auth_server

# Check if Playwright is installed locally; if not, install it and the necessary browsers.
if ! npx --no-install playwright --version >/dev/null 2>&1; then
  echo "Playwright is not installed. Installing Playwright..."
  npm install --no-audit --no-fund -D @playwright/test
fi
echo "Ensuring Playwright browsers are installed..."
npx playwright install --with-deps

npx playwright test auth.e2e.spec.ts --workers=1 --reporter=line

# Tear down the test environment after tests complete.
docker compose -f "$COMPOSE_FILE" down -v
