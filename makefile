.PHONY: base
base:
	cd core/base/install && terraform init
	cd core/base/config && terraform init

	cd core/base/install && terraform apply --auto-approve --lock-timeout=300s
	cd core/base/config && terraform apply --auto-approve --lock-timeout=300s

.PHONY: ci-runner
ci-runner:
	cd ci-runner && terraform init
	cd ci-runner && terraform apply --auto-approve --lock-timeout=300s
