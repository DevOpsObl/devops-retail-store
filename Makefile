ENV ?= dev
IMAGE_TAG ?= latest
AUTO_APPROVE ?=
APPLY_ARGS := $(if $(AUTO_APPROVE),$(AUTO_APPROVE) )

INFRA_DIR := infra
TF_DIR := $(INFRA_DIR)/environment
BOOTSTRAP_DIR := $(INFRA_DIR)/bootstrap
REGISTRY_DIR := $(INFRA_DIR)/registry

.PHONY: bootstrap-init bootstrap-plan bootstrap-apply bootstrap-destroy registry-init registry-plan registry-apply registry-destroy registry-validate init plan apply destroy validate output-alb-dns-name fmt

bootstrap-init:
	terraform -chdir=$(BOOTSTRAP_DIR) init

bootstrap-plan:
	terraform -chdir=$(BOOTSTRAP_DIR) plan -var-file=tfvars/shared.tfvars

bootstrap-apply:
	terraform -chdir=$(BOOTSTRAP_DIR) apply $(APPLY_ARGS)-var-file=tfvars/shared.tfvars

bootstrap-destroy:
	terraform -chdir=$(BOOTSTRAP_DIR) destroy $(APPLY_ARGS)-var-file=tfvars/shared.tfvars

registry-init:
	terraform -chdir=$(REGISTRY_DIR) init -reconfigure -backend-config=backend/$(ENV).hcl

registry-plan:
	terraform -chdir=$(REGISTRY_DIR) plan -var-file=tfvars/$(ENV).tfvars

registry-apply:
	terraform -chdir=$(REGISTRY_DIR) apply $(APPLY_ARGS)-var-file=tfvars/$(ENV).tfvars

registry-destroy:
	terraform -chdir=$(REGISTRY_DIR) destroy $(APPLY_ARGS)-var-file=tfvars/$(ENV).tfvars

registry-validate:
	terraform -chdir=$(REGISTRY_DIR) validate

init:
	terraform -chdir=$(TF_DIR) init -reconfigure -backend-config=backend/$(ENV).hcl

plan:
	terraform -chdir=$(TF_DIR) plan -var-file=tfvars/$(ENV).tfvars -var="image_tag=$(IMAGE_TAG)"

apply:
	terraform -chdir=$(TF_DIR) apply $(APPLY_ARGS)-var-file=tfvars/$(ENV).tfvars -var="image_tag=$(IMAGE_TAG)"

destroy:
	terraform -chdir=$(TF_DIR) destroy $(APPLY_ARGS)-var-file=tfvars/$(ENV).tfvars -var="image_tag=$(IMAGE_TAG)"

validate:
	terraform -chdir=$(TF_DIR) validate

output-alb-dns-name:
	@terraform -chdir=$(TF_DIR) output -raw alb_dns_name

fmt:
	terraform fmt -recursive $(INFRA_DIR)
