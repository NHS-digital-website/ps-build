include .mk

ANSIBLE_CONFIG ?= ansible/ansible.cfg
AWS_BUILD_INSTANCE_TYPE ?= t2.micro
AWS_BUILD_SUBNET_ID ?=
AWS_BUILD_VPC_ID ?=
PWD = $(shell pwd)
REGION ?= eu-west-1
ROLE ?=
USERNAME ?=
VENV ?= $(PWD)/.venv
VERSION ?= $(shell git describe --tags)
VERSION_ROLE ?= $(shell (cat .artefacts/$(ROLE).yml 2>/dev/null || echo "$(ROLE): { version: no-service }") | shyaml get-value '$(ROLE).version')

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
	@(printenv TOKEN > /dev/null && aws-sudo -m $(TOKEN) $(PROFILE) ) || ( \
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
			--exclude=ansible/roles/vendor
	@echo "Ansible Syntax Check..."
	$(MAKE) ansible.check ROLE=base_image
	$(MAKE) ansible.check ROLE=hippo_authoring
	$(MAKE) ansible.check ROLE=hippo_delivery

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

## Check syntax for given ROLE
# Usage: make ansible.check ROLE=hippo_authoring
ansible.check: $(VENV) ansible/roles/vendor
	ansible-playbook --syntax-check \
		--inventory ansible/inventories/localhost \
		--extra-vars hosts=localhost \
		--extra-vars role=$(ROLE) \
		--extra-vars root_dir=$(PWD)/ansible \
		--extra-vars @$(PWD)/vagrant/config.yml \
		$(EXTRAS) \
		ansible/playbooks/ami.yml

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
		-var 'build_name=$(shell get_build_name $(BUILD_NAME))' \
		-var 'build_version=$(VERSION)-$(VERSION_ROLE)' \
		-var 'role=$(ROLE)' \
		-var 'root_dir=$(PWD)/ansible' \
		"packer/ami.json"
	rm -rf self.tgz

ami.artefacts:
	$(MAKE) .artefacts/$(ROLE)-$(shell cat .artefacts/$(ROLE).yml | shyaml get-value $(ROLE).version).tgz ROLE=$(ROLE)

## Debug AMI build process
# Usage: make ami_debug ROLE=api_storelocator USERNAME=iam.key.name
ami.debug: .artefacts vendor/packer vendor/jq $(VENV) ansible/roles/vendor
	packer build -debug \
		-var 'aws_instance_type=$(AWS_BUILD_INSTANCE_TYPE)' \
		-var 'aws_region=$(REGION)' \
		-var 'aws_subnet_id=$(AWS_BUILD_SUBNET_ID)' \
		-var 'aws_vpc_id=$(AWS_BUILD_VPC_ID)' \
		-var 'base_ami_id=$(shell get_base_ami_id $(ROLE))' \
		-var 'build_name=$(shell ./bin/get_build_name $(BUILD_NAME))' \
		-var 'build_version=$(VERSION)-$(VERSION_ROLE)' \
		-var 'disable_stop_instance=true' \
		-var 'role=$(ROLE)' \
		-var 'root_dir=$(PWD)/ansible' \
		-var 'ssh_agent_auth=true' \
		-var 'ssh_keypair_name=$(USERNAME)' \
		"packer/ami.json"

## Builds and `ssh` to given machine.
# Startup and (re)provision local VM and then `ssh` to it for given ROLE.
# Usage: make vagrant ROLE=hippo_delivery
#        make vagrant ROLE=hippo_delivery MODE=configure
vagrant: $(VENV) vagrant.build .phony
	vagrant ssh

## Builds VM (only provision)
vagrant.build: ansible/roles/vendor
	@printenv ROLE || ( \
		echo "please specify ROLE, example: make vagrant ROLE=hippo_delivery" \
		&& exit 1 \
	)
	vagrant up --no-provision
	MODE="$(MODE)" vagrant provision
	@echo "- - - - - - - - - -"
	@echo "  Build Finished"
	@echo "- - - - - - - - - -"

## Watch changes and rebuild local VM
# This require `entr` (brew install entr)
# Usage: make vagrant.watch ROLE=hippo_delivery
vagrant.watch:
	while sleep 1; do \
		find ansible/ \
			vagrant/ \
			Vagrantfile \
		| entr -d $(MAKE) lint vagrant.build ROLE=$(ROLE); \
	done

## Executes given command on vagrant box
# Usage: make vagrant.exec ROLE=hippo_delivery COMMAND="echo 'Hello world!'"
vagrant.exec:
	@printenv ROLE || ( \
		echo "please specify ROLE, example: make vagrant ROLE=hippo_delivery" \
		&& exit 1 \
	)
	vagrant up --no-provision
	vagrant ssh -c "$(COMMAND)"

## Runs simple command on a given local VM.
# Usage: make vagrant.ssh ROLE=hippo_delivery
#        make vagrant.status ROLE=hippo_delivery
#        make vagrant.halt ROLE=hippo_delivery
#        make vagrant.destroy ROLE=hippo_delivery
vagrant.%:
	@printenv ROLE || ( \
		echo "please specify ROLE, example: make vagrant ROLE=hippo_delivery" \
		&& exit 1 \
	)
	MODE=$(MODE) vagrant $(subst vagrant.,,$@)

## Builds a vagrant VirtualBox ".box"
# This gives you working vagrant image box that you can share with others.
# Usage:
#   make box ROLE=api_kong
box: .artefacts/ubuntu-16.04.3-server-amd64.iso $(VENV) vendor/packer ansible/roles/vendor
	@mkdir -p .artefacts/boxes
	packer build \
		-var 'role=$(ROLE)' \
		-var 'root_dir=$(PWD)/ansible' \
		"packer/vagrant.json"

##
# usage: make build-deploy V=v1.1.5
build-deploy:
	o=$$(head -n2 .artefacts/hippo_delivery.yml; echo "  version: $(V)"); echo "$$o" > .artefacts/hippo_delivery.yml
	o=$$(head -n2 .artefacts/hippo_authoring.yml; echo "  version: $(V)"); echo "$$o" > .artefacts/hippo_authoring.yml
	unset VERSION_ROLE && make ami.artefacts ami ROLE=hippo_authoring
	unset VERSION_ROLE && make ami.artefacts ami ROLE=hippo_delivery
	cp .artefacts/hippo_*.yml ../ps-deploy/.artefacts/
	cd ../ps-deploy && make stack ROLE=hippo_authoring
	cd ../ps-deploy && make stack ROLE=hippo_delivery

## Create new version tag based on the nearest tag
version.bumpup:
	@git tag $$((git describe --abbrev=0 --tags | grep $$(cat .version) || echo $$(cat .version).-1) | perl -pe 's/^(v(\d+\.)*)(-?\d+)(.*)$$/$$1.($$3+1).$$4/e')
	$(MAKE) version.print

## Prints current version
version.print:
	@echo "- - -"
	@echo "Current version: $(VERSION)"
	@echo "- - -"

## Configure localhost
# ! DO NOT RUN LOCALLY !
# This target is designed to be used for bootstraping machine in given environment.
# Usage:
#   make ansible_configure_local ROLE=bastion
ansible_configure_local:
	cd ansible && ansible-playbook \
		-i inventories/localhost \
		-e role=$(ROLE) \
		-e root_dir=/bootstrap/ansible \
		-e @/bootstrap/environment.yml \
		--tags=configure \
		playbooks/bootstrap.yml

## Delete all downloaded and generated files
clean:
	rm -rf ansible/roles/vendor
	rm -rf $(VENV)
	find . -name "*.retry" | xargs rm

# shortcurt
.venv: $(VENV)

# setup Virtualenv
$(VENV):
	@which virtualenv > /dev/null || (\
		echo "please install virtualenv: http://docs.python-guide.org/en/latest/dev/virtualenvs/" \
		&& exit 1 \
	)
	virtualenv $(VENV)
	.venv/bin/pip install -r ansible/requirements.txt --ignore-installed
	# This ensures that on python < 2.7.9 we can accept SNI https connections
	.venv/bin/pip install -U urllib3[secure]
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

# Downloads ubuntu xenial iso image (for vagrant box build)
.artefacts/ubuntu-16.04.3-server-amd64.iso:
	curl -Lo .artefacts/ubuntu-16.04.3-server-amd64.iso \
		http://releases.ubuntu.com/16.04/ubuntu-16.04.3-server-amd64.iso

# Downloads Hippo distribution tgz
.artefacts/$(ROLE)-%.tgz:
	aws s3 cp \
		s3://artefacts.ps.digital.nhs.uk/$(ROLE)/$(patsubst .artefacts/$(ROLE)-%.tgz,%,$@)/website.tgz \
		$@

.log:
	mkdir -p .log

.phony:
