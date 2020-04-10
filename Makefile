SHELL := /usr/bin/env bash


# This renders all Jinja templates in the repo with your secure, gitignored values
render-all:
	@printf "Rendering all Jinja templates...\n"
	@find . -regex '.*_jinja.*' -print0 | xargs -0 -I{} python3 render-all.py {}


##################
# CloudFormation #
##################

# This is identical for create- and update-stack, so stuff into a Make variable
define cfn-create-update-args
--stack-name $(stackname) \
--template-body file://cloudformation/$(stackname).yaml \
--tags file://cloudformation/tags/tags.json
endef

# CloudFormation targets need a `stackname` variable passed in when called
check-stackname:
	@if [ -z "$(stackname)" ]; then printf 'You must provide a `stackname` parameter, e.g. `make create stackname=<x>`\n' && exit 1; fi

# This one's gonna look a little gross, sorry
get-bedrock-server-ip:
	@printf "Bedrock server IP: %s\n" \
	 	$$(aws cloudformation describe-stacks --stack-name bedrockServer | jq -r '.Stacks[0].Outputs | map(select(.OutputKey == "BedrockServerIP")) | .[0].OutputValue')

cfn-create: check-stackname render-all
	@printf "Trying to submit stack...\n"
	@aws cloudformation create-stack $(cfn-create-update-args)
	@printf "Stack submitted. Waiting for create completion...\n"
	@aws cloudformation wait stack-create-complete --stack-name $(stackname) || make -s cfn-delete stackname=$(stackname)
	@printf "Done.\n"
	@make -s get-bedrock-server-ip

cfn-update: check-stackname render-all
	@make -s check-stackname
	@printf "Trying to submit stack...\n"
	@aws cloudformation update-stack $(cfn-create-update-args)
	@printf "Stack submitted. Waiting for update completion...\n"
	@aws cloudformation wait stack-update-complete --stack-name $(stackname)
	@printf "Done.\n"
	@make -s get-bedrock-server-ip

cfn-delete: check-stackname render-all
	@make -s check-stackname
	@aws cloudformation delete-stack --stack-name $(stackname)
	@printf "Stack delete request sent. Waiting for delete completion...\n"
	@aws cloudformation wait stack-delete-complete --stack-name $(stackname)
	@printf "Done.\n"


###########
# Ansible #
###########
ansible-configure-bedrock-server: render-all
	@cd ansible && ansible-playbook main.yaml

ansible-configure-phantom-proxy:
	@cd ansible && ansible-playbook --key-file  -u pi main.yaml