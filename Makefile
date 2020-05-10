SHELL := /usr/bin/env bash


# accountNumber := $$(aws sts get-caller-identity --query Account --output text)
# bucket := minecraft-bedrock-server-$(accountNumber)


help:
	@printf "See Makefile for available targets\n"

check-variables:
	@if [[ -z "$${stackname}" ]]; then \
			printf "You must supply a 'stackname' environment variable. Aborting.\n" && exit 1; \
	fi

# This renders all Jinja templates in the repo with your secure, gitignored values
render-all:
	@printf "Rendering all Jinja templates...\n"
	@find . -regex '.*_jinja.*' -print0 | xargs -0 -I{} python3 render-all.py {}

# Send repo source to S3 to pull into EC2 userdata
# Make's shell interpretation makes variables kind of funky to work with here
push-source: render-all
	@source bedrock-server/scripts/get-variables.sh; \
	srcdir=`basename "$${PWD}"`; \
	cd .. \
	&& tar -czf $${srcdir}_source.tar.gz $${srcdir} \
	&& aws s3 cp $${srcdir}_source.tar.gz s3://$${bucket}/source.tar.gz


##################
# CloudFormation #
##################
cfn-deploy: check-variables push-source
	aws cloudformation deploy \
		--stack-name bedrockServer-$(stackname) \
		--template-file cloudformation/$(stackname).yaml \
		--tags 'Owner=ryapric@gmail.com' \
		--capabilities CAPABILITY_IAM

cfn-delete: check-variables
	@aws cloudformation delete-stack --stack-name bedrockServer-$(stackname)
	@printf "Stack delete request sent. Waiting for delete completion...\n"
	@aws cloudformation wait stack-delete-complete --stack-name bedrockServer-$(stackname)
	@printf "Done.\n"


###########
# Ansible #
###########
ansible-configure-phantom-proxy: render-all
	@cd ansible && ansible-playbook ./phantom-proxy/phantom-proxy.yaml
