ENV ?= dev
IMAGE_TAG ?= latest
AUTO_APPROVE ?=
APPLY_ARGS := $(if $(AUTO_APPROVE),$(AUTO_APPROVE) )
STATE_BUCKET ?= $(shell sed -n 's/^state_bucket_name *= *"\([^"]*\)".*/\1/p' infra/bootstrap/tfvars/shared.tfvars)

INFRA_DIR := infra
TF_DIR := $(INFRA_DIR)/environment
BOOTSTRAP_DIR := $(INFRA_DIR)/bootstrap
REGISTRY_DIR := $(INFRA_DIR)/registry

.PHONY: bootstrap-init bootstrap-plan bootstrap-apply bootstrap-empty-state-bucket bootstrap-destroy registry-init registry-plan registry-apply registry-destroy registry-validate init plan apply destroy validate output-alb-dns-name fmt

bootstrap-init:
	terraform -chdir=$(BOOTSTRAP_DIR) init

bootstrap-plan:
	terraform -chdir=$(BOOTSTRAP_DIR) plan -var-file=tfvars/shared.tfvars

bootstrap-apply:
	terraform -chdir=$(BOOTSTRAP_DIR) apply $(APPLY_ARGS)-var-file=tfvars/shared.tfvars

bootstrap-destroy:
	terraform -chdir=$(BOOTSTRAP_DIR) destroy $(APPLY_ARGS)-var-file=tfvars/shared.tfvars

bootstrap-empty-state-bucket:
	@test "$(CONFIRM_STATE_BUCKET_EMPTY)" = "yes" || (echo "Refusing to empty $(STATE_BUCKET). Re-run with CONFIRM_STATE_BUCKET_EMPTY=yes"; exit 1)
	@echo "Deleting object versions from s3://$(STATE_BUCKET)"
	@aws s3api list-object-versions --bucket "$(STATE_BUCKET)" --query 'Versions[].[Key,VersionId]' --output text | while read -r key version_id; do \
		if [ -n "$$key" ] && [ "$$key" != "None" ]; then \
			aws s3api delete-object --bucket "$(STATE_BUCKET)" --key "$$key" --version-id "$$version_id" >/dev/null; \
		fi; \
	done
	@echo "Deleting delete markers from s3://$(STATE_BUCKET)"
	@aws s3api list-object-versions --bucket "$(STATE_BUCKET)" --query 'DeleteMarkers[].[Key,VersionId]' --output text | while read -r key version_id; do \
		if [ -n "$$key" ] && [ "$$key" != "None" ]; then \
			aws s3api delete-object --bucket "$(STATE_BUCKET)" --key "$$key" --version-id "$$version_id" >/dev/null; \
		fi; \
	done

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
