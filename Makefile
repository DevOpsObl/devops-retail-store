ENV ?= dev

INFRA_DIR := infra
TF_DIR := $(INFRA_DIR)/environment
BOOTSTRAP_DIR := $(INFRA_DIR)/bootstrap

.PHONY: bootstrap-init bootstrap-plan bootstrap-apply init plan apply validate fmt

bootstrap-init:
	cd $(BOOTSTRAP_DIR) && terraform init

bootstrap-plan:
	cd $(BOOTSTRAP_DIR) && terraform plan -var-file=tfvars/shared.tfvars

bootstrap-apply:
	cd $(BOOTSTRAP_DIR) && terraform apply -var-file=tfvars/shared.tfvars

init:
	cd $(TF_DIR) && terraform init -reconfigure -backend-config=backend/$(ENV).hcl

plan:
	cd $(TF_DIR) && terraform plan -var-file=tfvars/$(ENV).tfvars

apply:
	cd $(TF_DIR) && terraform apply -var-file=tfvars/$(ENV).tfvars

validate:
	cd $(TF_DIR) && terraform validate

fmt:
	terraform fmt -recursive $(INFRA_DIR)
