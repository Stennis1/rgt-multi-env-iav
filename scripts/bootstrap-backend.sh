#!/usr/bin/env bash
# Solves the chicken-and-egg problem: Terraform's S3 backend needs the bucket
# to already exist before `terraform init` will succeed, but we don't want to
# create that bucket WITH Terraform (that would mean the state backend's own
# existence isn't tracked by any state - a bootstrapping paradox).
#
# Fix: create the bucket with the MinIO client (mc), completely outside
# Terraform, as a one-time (idempotent) step. This mirrors how you'd bootstrap
# an S3 bucket + DynamoDB lock table by hand (or via a separate "bootstrap"
# Terraform root with local state) before pointing your real environments at it.
set -euo pipefail

MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://localhost:9000}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin}"
BUCKET_NAME="${BUCKET_NAME:-tfstate}"

echo "Waiting for MinIO at ${MINIO_ENDPOINT}..."
for i in $(seq 1 30); do
  if curl -sf "${MINIO_ENDPOINT}/minio/health/live" > /dev/null; then
    break
  fi
  sleep 1
done

mc alias set localminio "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

if mc ls "localminio/${BUCKET_NAME}" > /dev/null 2>&1; then
  echo "Bucket '${BUCKET_NAME}' already exists - nothing to do."
else
  mc mb "localminio/${BUCKET_NAME}"
  echo "Created bucket '${BUCKET_NAME}'."
fi

# Enable versioning: cheap insurance against accidental state corruption/overwrite.
mc version enable "localminio/${BUCKET_NAME}" || true

echo "Backend bucket ready."
