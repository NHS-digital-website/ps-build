# Vagrant Box




## Run Vagrant Box

First you need to manually add (download) vagrant box by running:

```
vagrant box add hippo_authoring.box nhsd/hippo_authoring
```

Then, copy this Vagrantfile to your project.

```
Vagrant.configure(2) do |config|
    config.vm.box = "nhsd/hippo_authoring"
    config.vm.synced_folder ".", "/vagrant", disabled: true
end
```

Then run `vagrant up` in the same folder where you've put Vagrantfile. Once it's
done, you can access hippo on http://hippo-authoring.nhsd-ps.int.

You can login to the box using `vagrant ssh` and change anything you want. If
after some time you would like to discard all your changes simply run `vagrant
destroy` and then `vagrant up` again to get fresh box.




## Build New Vagrant Box

You can build and release new vagrant boxes using couple of commands. It's not
fully automated. When it will become a proper project requirement we will automate
this processes fully.

To build and release new `hippo_authoring` box follow these steps:

* `make box ROLE=hippo_authoring` to build box file
* `$(make aws-sudo PROFILE=nhsd-nonprod TOKEN=123789)` get AWS credentials
* `cd .artefacts/boxes/hippo_authoring`
* Download current box metadata `../../../.venv/bin/aws s3 cp s3://boxes.ps.digital.nhs.uk/hippo_authoring ./metadata.json`
* View the `metadata.json` and decide what the next version should be.
* Rename latest build to given version: `mv latest <VERSION>`
* Update metadata.json file by running `../../../.venv/bin/vagrant-metadata -a`
* Upload box file to S3
  ```
  ../../../.venv/bin/aws \
    s3 cp \
    <VERSION>/virtualbox/hippo_authoring.box \
    s3://boxes.ps.digital.nhs.uk/hippo_authoring/<VERSION>/virtualbox/hippo_authoring.box
  ```
* Upload `metadata.json` to S3
  ```BASH
  ../../../.venv/bin/aws \
    s3 cp \
    metadata.json \
    s3://boxes.ps.digital.nhs.uk/hippo_authoring
  ```
