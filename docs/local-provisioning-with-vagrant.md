# Local Provisioning With Vagrant

Each components/service can be provisioned locally using Vagrant.




## Building Components Locally

In order to provision VirtualBox machine using Vagrant simply run:

```
make vagrant ROLE=hippo_authoring
```

to stop, reload or destroy run

```
# stop
make vagrant.halt ROLE=hippo_authoring

# restart / reload
make vagrant.reload ROLE=hippo_authoring

# destroy
make vagrant.destroy ROLE=hippo_authoring
```
