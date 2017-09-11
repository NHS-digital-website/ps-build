# NHS Digital Publication System

master branch [![Build Status](https://travis-ci.org/NHS-digital-website/ps-build.svg?branch=master)](https://travis-ci.org/NHS-digital-website/ps-build),
develop branch [![Build Status](https://travis-ci.org/NHS-digital-website/ps-build.svg?branch=develop)](https://travis-ci.org/NHS-digital-website/ps-build).

This project allows you to build all components of the Publication System. You can
build local [Vagrant](https://www.vagrantup.com/) box or
[AMI](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html).

In order to use this project you need:

* [python virtualenv](http://docs.python-guide.org/en/latest/dev/virtualenvs/).
* [shellcheck](https://www.shellcheck.net/)

If you want to build artefacts locally you would also need:

* [Vagrant](https://www.vagrantup.com/downloads.html)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

To quickly setup this project run `make init`. To get more help, simply run
`make help`.




## Documentation

* [Makefile](docs/makefile.md)
* [Local Provisioning With Vagrant](docs/local-provisioning-with-vagrant.md)
* [Contributors' Workflow](docs/contributors-workflow.md)

Advanced topics:

* [Before `push` Checklist](docs/before-push-checklist.md)
* [Building AMI](docs/building-ami.md)
* [Vagrant Box](docs/vagrant-box.md)
