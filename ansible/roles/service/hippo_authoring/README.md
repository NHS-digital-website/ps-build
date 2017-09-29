# Hippo Authoring Application

Build and configure Hippo CMS Authoring components.

You have to specify `hippo_authoring.download_type`.




## Tags

This role uses the following tags

* `build` to build AMI. This includes downloading given version of hippo app
* `configure` to configure/bootstrap once AMI is started in an environment




## Playbooks

You will find 2 playbooks in the root folder of this role

* `context.yml` can be used to build all sorts of dependencies, configuration files
  and everything else that might be required to run hippo_authoring on a single box.
* `playbook.yml` builds hippo_authoring app.
