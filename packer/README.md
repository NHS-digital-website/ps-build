# Packer

Packer takes care of a lot of little annoying things giving you time to think about
the important bits.

Currently it's used to build AMIs (Amazon Machine Images).




## AMI Build Process

Start EC2 box in VPC (Virtual Private Cloud) using parent AMI, run `ami.yml`
playbook against that box to finally stop VM and save as AMI.
