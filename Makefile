SHELL := /usr/bin/env bash

# CloudFormation CLI is super verbose, so this is nice to have

# This is identical for create- and update-stack, so stuff into a Make variable
define cfn-create-update-args
--stack-name $(stackname) \
--template-body file://stacks/$(stackname).yaml \
--parameters file://parameters/$(stackname).json \
--tags file://tags/tags.json
endef


# This renders all Jinja templates in the repo with your secure, gitignored values
render-all:
	@find . -regex '.*_jinja.*' -print0 | xargs -0 -I{} python3 render-all.py {}


# CloudFormation targets need a `stackname` variable passed in when called
check-stackname:
	@if [ -z "$(stackname)" ]; then printf 'You must provide a `stackname` parameter, e.g. `make create stackname=<x>`\n' && exit 1; fi

create:
	@make -s check-stackname
	@printf "Trying to submit stack...\n"
	@aws cloudformation create-stack $(cfn-create-update-args)
	@printf "Stack submitted. Waiting for create completion...\n"
	@aws cloudformation wait stack-create-complete --stack-name $(stackname) || make -s delete stackname=$(stackname)
	@printf "Done.\n"

update:
	@make -s check-stackname
	@printf "Trying to submit stack...\n"
	@aws cloudformation update-stack $(cfn-create-update-args)
	@printf "Stack submitted. Waiting for update completion...\n"
	@aws cloudformation wait stack-update-complete --stack-name $(stackname)
	@printf "Done.\n"

delete:
	@make -s check-stackname
	@aws cloudformation delete-stack --stack-name $(stackname)
	@printf "Stack delete request sent. Waiting for delete completion...\n"
	@aws cloudformation wait stack-delete-complete --stack-name $(stackname)
	@printf "Done.\n"
