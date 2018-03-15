
modules = $(shell find . -type f -name "*.tf" -exec dirname {} \;|sort -u)

.PHONY: test

default: test

test:
	@for m in $(modules); do (terraform validate "$$m" && echo "√ $$m") || exit 1 ; done

fmt:
	@if [ `terraform fmt | wc -c` -ne 0 ]; then echo "terraform files need be formatted"; exit 1; fi

init: ## Initializes the terraform remote state backend and pulls the correct environments state.
	@if [ -z $(BUCKET) ]; then echo "BUCKET was not set" ; exit 10 ; fi
	@if [ -z $(PROJECT) ]; then echo "PROJECT was not set" ; exit 10 ; fi
	@rm -rf .terraform/*.tf*
	@terraform init \
        -backend-config="bucket=${BUCKET}" \
        -backend-config="key=terraform/terraform-aws-base.tfstate" \
        -backend-config="region=us-east-1"
