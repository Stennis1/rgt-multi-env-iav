SHELL := /bin/bash
ENV ?= staging

.PHONY: minio-up minio-down bootstrap init plan apply destroy verify fmt validate lint

## Bring up the local MinIO "state backend" (S3-compatible)
minio-up:
	docker run -d --rm --name minio \
		-p 9000:9000 -p 9001:9001 \
		-e MINIO_ROOT_USER=minioadmin \
		-e MINIO_ROOT_PASSWORD=minioadmin \
		minio/minio server /data --console-address ":9001"

minio-down:
	docker stop minio || true

## Create the tfstate bucket before first init (chicken-and-egg fix)
bootstrap:
	./scripts/bootstrap-backend.sh

fmt:
	terraform fmt -recursive

validate:
	cd environments/$(ENV) && terraform validate

lint:
	tflint --chdir=environments/$(ENV)

init:
	cd environments/$(ENV) && terraform init

plan:
	cd environments/$(ENV) && TF_VAR_db_password=$${TF_VAR_db_password:-devlocalpassword} terraform plan

apply:
	cd environments/$(ENV) && TF_VAR_db_password=$${TF_VAR_db_password:-devlocalpassword} terraform apply -auto-approve

destroy:
	cd environments/$(ENV) && TF_VAR_db_password=$${TF_VAR_db_password:-devlocalpassword} terraform destroy -auto-approve

## Proof of isolation - run after `make apply ENV=staging`
verify:
	./scripts/verify-isolation.sh $(ENV)
