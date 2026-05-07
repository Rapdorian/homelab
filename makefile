.PHONY: base
base:
	cd core/base/install && terraform init
	cd core/base/config && terraform init

	cd core/base/install && terraform apply --auto-approve --lock-timeout=300s
	cd core/base/config && terraform apply --auto-approve --lock-timeout=300s

.PHONY: core-storage
core-storage:
	cd core/storage && terraform init
	cd core/storage && terraform apply --auto-approve --lock-timeout=300s

.PHONY: core-identity
core-identity:
	cd core/identity && terraform init
	cd core/identity && terraform apply --auto-approve --lock-timeout=300s

.PHONY: core
core: base core-storage core-identity

.PHONY: ci-runner
ci-runner:
	cd ci-runner && terraform init
	cd ci-runner && terraform apply --auto-approve --lock-timeout=300s
