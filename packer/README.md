# Packer

Packer takes care of a lot of little annoying things giving you time to think about
the important bits.

Currently it's used to build AMIs (Amazon Machine Images).




## AMI Build Process

Start EC2 box in VPC (Virtual Private Cloud) using parent AMI, run `ami.yml`
playbook against that box to finally stop VM and save as AMI.




## The vagrant.json File

The 'provisioners' section in vagrant.json might look complicated and scary, but
in reality it's very simple.

First `shell` provisioner ensures that the box is ready for next provision steps

Next you will find a series of `ansible` provisioners. First one will ensure that
the "base_image" role is applied. Next 3 provisioners will

* Run the role's playbook.yml with `build` tag.
* Run the role's context.yml with `build` and `configure` tag.
* Run the role's playbook.yml with `dev_setup` tag.

This order ensures that all local, dev and production boxes work and behave almost
identically.

The last `shell` step removes any unwanted files and prepare the VM for shutdown.
