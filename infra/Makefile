ENV ?= dev

TF_DIR := environment

.PHONY: bootstrap-init bootstrap-plan bootstrap-apply init plan apply validate fmt

bootstrap-init:
	cd bootstrap && terraform init

bootstrap-plan:
	cd bootstrap && terraform plan -var-file=tfvars/shared.tfvars

bootstrap-apply:
	cd bootstrap && terraform apply -var-file=tfvars/shared.tfvars

init:
	cd $(TF_DIR) && terraform init -reconfigure -backend-config=backend/$(ENV).hcl

plan:
	cd $(TF_DIR) && terraform plan -var-file=tfvars/$(ENV).tfvars

apply:
	cd $(TF_DIR) && terraform apply -var-file=tfvars/$(ENV).tfvars

validate:
	cd $(TF_DIR) && terraform validate

fmt:
	terraform fmt -recursive .
