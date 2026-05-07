.PHONY: base
base:
	cd core/base/install && rm -rf .terraform && terraform init && \
	terraform apply --auto-approve --lock-timeout=300s
	cd core/base/config && rm -rf .terraform && terraform init && \
	terraform apply --auto-approve --lock-timeout=300s

.PHONY: core-storage
core-storage:
	cd core/storage && rm -rf .terraform && terraform init && \
	terraform apply --auto-approve --lock-timeout=300s

.PHONY: core-identity
core-identity:
	cd core/identity && rm -rf .terraform && terraform init && \
	terraform apply --auto-approve --lock-timeout=300s

.PHONY: core
core: base core-storage core-identity

.PHONY: ci-runner-secret
ci-runner-secret:
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is not set. Usage: make ci-runner-secret GITHUB_TOKEN=<token>)
endif
	kubectl create secret generic github-token \
		--namespace arc-systems \
		--from-literal=github_token='$(GITHUB_TOKEN)' \
		--dry-run=client -o yaml | kubectl apply -f -

.PHONY: ci-runner
ci-runner:
	cd ci-runner && rm -rf .terraform && terraform init && \
	terraform apply --auto-approve --lock-timeout=300s
