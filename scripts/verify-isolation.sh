#!/usr/bin/env bash
# Proof of isolation for a given environment (staging|production).
# Usage: ./scripts/verify-isolation.sh staging
set -euo pipefail

ENV="${1:?usage: verify-isolation.sh <staging|production>}"
API_CONTAINER="${ENV}-api-0"
EDGE_CONTAINER="${ENV}-nginx"
DB_CONTAINER="${ENV}-postgres"
DB_HOST="${DB_CONTAINER}"
DB_PORT=5432

pass=0
fail=0

echo "== Verifying network isolation for '${ENV}' =="

# Probe from a throwaway busybox container sharing the target's network
# namespace (`--network container:<name>`), rather than `docker exec` into
# the target itself. The api container runs hashicorp/http-echo, a scratch
# image with no shell/package manager, so exec-ing a shell into it isn't an
# option - this approach works regardless of what's inside the target image.
probe() {
  local target="$1"
  docker run --rm --network "container:${target}" busybox:1.36 nc -z -w 3 "${DB_HOST}" "${DB_PORT}" > /dev/null 2>&1
}

echo -n "[1/2] API (compute tier) -> Postgres:${DB_PORT}  expect SUCCESS ... "
if probe "${API_CONTAINER}"; then
  echo "PASS (reachable, as expected)"
  pass=$((pass+1))
else
  echo "FAIL (should have been reachable)"
  fail=$((fail+1))
fi

echo -n "[2/2] Nginx (edge tier) -> Postgres:${DB_PORT}  expect FAILURE ... "
if probe "${EDGE_CONTAINER}"; then
  echo "FAIL (edge tier reached the DB - isolation broken!)"
  fail=$((fail+1))
else
  echo "PASS (unreachable, as expected - no shared network with db_internal)"
  pass=$((pass+1))
fi

echo
echo "Result: ${pass} passed, ${fail} failed."
if [ "${fail}" -ne 0 ]; then
  exit 1
fi
