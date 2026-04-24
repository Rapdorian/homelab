include .env
export

apply:
	terraform apply --auto-approve

destroy:
	terraform destroy --auto-approve
