include .mk

ROLE ?=
VENV ?= .venv
PWD = $(shell pwd)
ANSIBLE_CONFIG ?= ansible/ansible.cfg

PATH := $(VENV)/bin:$(shell printenv PATH)
SHELL := env PATH=$(PATH) /bin/bash

export PATH
export ANSIBLE_CONFIG

.PHONY: .phony

## Prints this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		 skip  { next } \
		 /^#/  { doc=doc "\n" substr($$0, 2); next } \
		 /:/   { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)

## Lint all the code
# Usage: make lint
lint: lint.ansible

## Lint Ansible roles and playbooks
lint.ansible:
	@echo "Ansible Roles Lint..."
	@find ansible/roles/service -name "*.yml" -not -path "*/files/*.yml" -print0 | \
	xargs -n1 -0 -I% \
		ansible-lint % \
			--exclude=ansible/roles/vendor \

$(VENV):
	@which virtualenv > /dev/null || (echo "please install virtualenv: http://docs.python-guide.org/en/latest/dev/virtualenvs/" && exit 1)
	virtualenv $(VENV)
	.venv/bin/pip install -U "pip<9.0"
	.venv/bin/pip install pyopenssl urllib3[secure] requests[security]
	.venv/bin/pip install -r ansible/requirements.txt --ignore-installed
	virtualenv --relocatable $(VENV)

ansible/roles/vendor: $(VENV) .phony
	ansible-galaxy install -p ansible/roles/vendor -r ansible/roles/vendor.yml --ignore-errors

## Builds and `ssh` to given machine.
# Startup and (re)provision local VM and then `ssh` to it for given ROLE.
# Example: make vagrant ROLE=hippocms
#	  make vagrant ROLE=hippocms MODE=configure
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
# Example: make vagrant.watch ROLE=hippocms
vagrant.watch:
	while sleep 1; do \
		find ansible/ \
			vagrant/ \
			Vagrantfile \
		| entr -d $(MAKE) lint vagrant.build ROLE=$(ROLE); \
	done

## Runs simple command on a given local VM.
# Example: make vagrant.ssh ROLE=hippocms
#	  make vagrant.status ROLE=hippocms
#	  make vagrant.halt ROLE=hippocms
#	  make vagrant.destroy ROLE=hippocms
vagrant.%:
	MODE=$(MODE) vagrant $(subst vagrant.,,$@)

## Delete all downloaded and generated files
clean:
	rm -rf ansible/roles/vendor
	rm -rf $(VENV)

# generates empty .mk file if not present
.mk:
	touch .mk
