include .env
export

apply:
	terraform init --upgrade
	terraform apply --auto-approve

destroy:
	terraform destroy --auto-approve
