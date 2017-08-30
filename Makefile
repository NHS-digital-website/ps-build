include .mk

ANSIBLE_CONFIG ?= ansible/ansible.cfg
AWS_BUILD_INSTANCE_TYPE ?= t2.micro
AWS_BUILD_SUBNET_ID ?=
AWS_BUILD_VPC_ID ?=
PWD = $(shell pwd)
REGION ?= eu-west-1
ROLE ?=
VENV ?= .venv

# Ansible 2.2.1 introduced a bug with paths for "local" connections
export HOME

PATH := $(VENV)/bin:$(PWD)/vendor:$(PWD)/bin:$(shell printenv PATH)
SHELL := env PATH=$(PATH) /bin/bash

export ANSIBLE_CONFIG
export AWS_DEFAULT_REGION=$(REGION)
export AWS_REGION=$(REGION)
export PATH

.PHONY: .phony

## Prints this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		 skip  { next } \
		 /^#/  { doc=doc "\n" substr($$0, 2); next } \
		 /:/   { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)

## Initialise local project
init: .git/.local-hooks-installed $(VENV)

## Sudo for AWS Roles
# Usage: $(make aws-sudo TOKEN=123789)
aws-sudo: $(VENV)
	@(printenv TOKEN && aws-sudo -m $(TOKEN) $(PROFILE) ) || ( \
		aws-sudo $(PROFILE) \
	)

## Install vendor dependencies such as Packer
vendor: vendor/packer vendor/jq

# install Packer
vendor/packer:
	mkdir -p vendor
	bash bin/install_local_packer 1.0.4

# install JQ
vendor/jq:
	mkdir -p vendor
	bash bin/install_local_jq 1.5

## Lint all the code
# Usage: make lint
lint: lint.python lint.bash lint.ansible

## Lint Python scripts
lint.python: $(VENV)
	@echo "Lint Python code..."
	@grep -Rn python bin \
		| grep ":1:" \
		| sed -E 's/([^:]*):.*/\1/' \
		| xargs -I% pep8 %

## Lint Ansible roles and playbooks
lint.ansible: $(VENV)
	@echo "Lint Ansible Roles..."
	@find ansible/roles/service -name "*.yml" -not -path "*/files/*.yml" -print0 | \
	xargs -n1 -0 -I% \
		ansible-lint % \
			--exclude=ansible/roles/vendor \

## Lint Bash scripts
lint.bash:
	@which shellcheck > /dev/null || (\
		echo "please install shellcheck: https://github.com/koalaman/shellcheck#user-content-installing" \
		&& exit 1 \
	)
	@echo "Lint Bash code..."
	@grep -Rn "/bash" bin \
			| grep ":1:" \
			| sed -E 's/([^:]*):.*/\1/' \
			| xargs -I% bash -c 'cd $$(dirname %) && shellcheck -x $(PWD)/%'

## Builds an AMI using an Ansible role
#
# BUILD_NAME must be specified, in GoCD this should be the
# job number, outside of GoCD a dummy handle should be used
# so as to not collide with GoCD build numbers
#
# Usage: make ami ROLE=bastion BUILD_NAME=test1
ami: .artefacts .log vendor/packer vendor/jq $(VENV) ansible/roles/vendor
	packer build \
		-var 'aws_instance_type=$(AWS_BUILD_INSTANCE_TYPE)' \
		-var 'aws_region=$(REGION)' \
		-var 'aws_subnet_id=$(AWS_BUILD_SUBNET_ID)' \
		-var 'aws_vpc_id=$(AWS_BUILD_VPC_ID)' \
		-var 'base_ami_id=$(shell get_base_ami_id $(ROLE))' \
		-var 'build_name=$(shell ./bin/get_build_name $(BUILD_NAME))' \
		-var 'build_version=$(shell ./bin/get_repo_version)' \
		-var 'root_dir=$(PWD)/ansible' \
		-var 'role=$(ROLE)' \
		"packer/ami.json"

## Debug AMI build process
# Usage: make ami_debug ROLE=api_storelocator USERNAME=iam.key.name
ami_debug: .artefacts vendor/packer vendor/jq $(VENV) ansible/roles/vendor
	packer build -debug \
		-var 'aws_instance_type=t2.micro' \
		-var 'aws_region=$(REGION)' \
		-var 'aws_subnet_id=$(shell shyaml get-value aws.build.subnet < .config.yml)' \
		-var 'aws_vpc_id=$(shell shyaml get-value aws.build.vpc_id < .config.yml)' \
		-var 'base_ami_id=$(shell shyaml get-value aws.ami.ubuntu_xenail.id < .build.yml)' \
		-var 'build_name=$(shell ./bin/get_build_name $(BUILD_NAME))' \
		-var 'build_version=$(shell ./bin/get_repo_version)' \
		-var 'disable_stop_instance=true' \
		-var 'ssh_keypair_name=$(USERNAME)' \
		-var 'ssh_agent_auth=true' \
		-var 'root_dir=$(PWD)/ansible' \
		-var 'role=$(ROLE)' \
		"packer/ami.json"

## Builds and `ssh` to given machine.
# Startup and (re)provision local VM and then `ssh` to it for given ROLE.
# Usage: make vagrant ROLE=hippocms
#        make vagrant ROLE=hippocms MODE=configure
vagrant: $(VENV) vagrant.build .phony
	vagrant ssh

## Builds VM (only provision)
vagrant.build: ansible/roles/vendor
	@printenv ROLE || ( \
		echo "please specify ROLE, example: make vagrant ROLE=hippocms" \
		&& exit 1 \
	)
	vagrant up --no-provision
	MODE="$(MODE)" vagrant provision
	@echo "- - - - - - - - - -"
	@echo "  Build Finished"
	@echo "- - - - - - - - - -"

## Watch changes and rebuild local VM
# This require `entr` (brew install entr)
# Usage: make vagrant.watch ROLE=hippocms
vagrant.watch:
	while sleep 1; do \
		find ansible/ \
			vagrant/ \
			Vagrantfile \
		| entr -d $(MAKE) lint vagrant.build ROLE=$(ROLE); \
	done

## Runs simple command on a given local VM.
# Usage: make vagrant.ssh ROLE=hippocms
# make vagrant.status ROLE=hippocms
#      make vagrant.halt ROLE=hippocms
#      make vagrant.destroy ROLE=hippocms
vagrant.%:
	MODE=$(MODE) vagrant $(subst vagrant.,,$@)

## Delete all downloaded and generated files
clean:
	rm -rf ansible/roles/vendor
	rm -rf $(VENV)

$(VENV):
	@which virtualenv > /dev/null || (\
		echo "please install virtualenv: http://docs.python-guide.org/en/latest/dev/virtualenvs/" \
		&& exit 1 \
	)
	virtualenv $(VENV)
	.venv/bin/pip install -U "pip<9.0"
	.venv/bin/pip install pyopenssl urllib3[secure] requests[security]
	.venv/bin/pip install -r ansible/requirements.txt --ignore-installed
	virtualenv --relocatable $(VENV)

ansible/roles/vendor: $(VENV) .phony
	ansible-galaxy install -p ansible/roles/vendor -r ansible/roles/vendor.yml --ignore-errors

# generates empty .mk file if not present
.mk:
	touch .mk

# install hooks and local git config
.git/.local-hooks-installed:
	@bash .git-local/install

.artefacts:
	mkdir -p .artefacts

.artefacts/%.yml: .artefacts
	bin/create_latest_artifact $@

.log:
	mkdir -p .log
