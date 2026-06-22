ENV ?= dev
IMAGE_TAG ?= latest

INFRA_DIR := infra
TF_DIR := $(INFRA_DIR)/environment
BOOTSTRAP_DIR := $(INFRA_DIR)/bootstrap
REGISTRY_DIR := $(INFRA_DIR)/registry

.PHONY: bootstrap-init bootstrap-plan bootstrap-apply registry-init registry-plan registry-apply registry-validate init plan apply validate fmt

bootstrap-init:
	cd $(BOOTSTRAP_DIR) && terraform init

bootstrap-plan:
	cd $(BOOTSTRAP_DIR) && terraform plan -var-file=tfvars/shared.tfvars

bootstrap-apply:
	cd $(BOOTSTRAP_DIR) && terraform apply -var-file=tfvars/shared.tfvars

registry-init:
	cd $(REGISTRY_DIR) && terraform init -reconfigure -backend-config=backend/$(ENV).hcl

registry-plan:
	cd $(REGISTRY_DIR) && terraform plan -var-file=tfvars/$(ENV).tfvars

registry-apply:
	cd $(REGISTRY_DIR) && terraform apply -var-file=tfvars/$(ENV).tfvars

registry-validate:
	cd $(REGISTRY_DIR) && terraform validate

init:
	cd $(TF_DIR) && terraform init -reconfigure -backend-config=backend/$(ENV).hcl

plan:
	cd $(TF_DIR) && terraform plan -var-file=tfvars/$(ENV).tfvars -var="image_tag=$(IMAGE_TAG)"

apply:
	cd $(TF_DIR) && terraform apply -var-file=tfvars/$(ENV).tfvars -var="image_tag=$(IMAGE_TAG)"

validate:
	cd $(TF_DIR) && terraform validate

fmt:
	terraform fmt -recursive $(INFRA_DIR)
