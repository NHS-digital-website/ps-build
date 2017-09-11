# Building AMI

This project is all about building infrastructure components - mainly AMIs. In
order to do so, you have to make sure that your local project is setup correctly
and that you have sufficient AWS permission.




## AWS CLI

AWS CLI is installed automatically in virtualenv when you run any `make` command
that uses it. You still have to configure your AWS profiles and credentials
correctly.

in `~/.aws/config`

```
[profile nhsd-website-nonprod]
output = json
region = eu-west-1

[profile nhsd-website-prod]
output = json
region = eu-west-1
```

in `~/.aws/credentials`

```
[profile nhsd-website-nonprod]
aws_access_key_id = ABCAJBCFVV63UJ9X8Y7Z
aws_secret_access_key = aDghW512HJ...
mfa_serial = arn:aws:iam::ACCOUNT-ID:mfa/firstname.lastname

[profile nhsd-website-prod]
aws_access_key_id = V6BCF3UABCAJVJ9X8Y7Z
aws_secret_access_key = hjQgau3yAHY5...
mfa_serial = arn:aws:iam::ACCOUNT-ID:mfa/firstname.lastname
```

Now, to test your profile you can:

```
$(make aws-sudo PROFILE=nhsd-website-nonprod TOKEN=321456)
```




## Building

Building AMI is as easy as running:

```
make ami ROLE=base_image
```




## Debugging

If you want to debug, you need a IAM ssh key to be present, ideally called
"firstname.lastname", and you need to pass that name as "USERNAME" to `ami.debug`
command.

```
make ami.debug ROLE=base_image USERNAME=firstname.lastname
```

Once the EC2 is up and running, you will see it's details on the screen

```
...
==> amazon-ebs: Waiting for instance (i-0cdc4ca1049f256af) to become ready...
==> amazon-ebs: Adding tags to source instance
    amazon-ebs: Adding tag: "build_repo_version": ""
    amazon-ebs: Adding tag: "Name": "ami-builder-base_image-CW-357-2017.09.12-RYaROBm"
    amazon-ebs: Adding tag: "Role": "base_image"
    amazon-ebs: Adding tag: "Version": "CW-357"
    amazon-ebs: Public DNS: ec2-52-19-0-183.eu-west-1.compute.amazonaws.com
    amazon-ebs: Public IP: 52.19.0.183
    amazon-ebs: Private IP: 172.31.47.114
==> amazon-ebs: Pausing after run of step 'StepRunSourceInstance'. Press enter to continue.
...
```

You can now ssh to it using the private IP and `ubuntu` user and wait for the
Ansible to kick in.

When Ansible is done (with or without error) you will see something like:

```
amazon-ebs: PLAY RECAP *********************************************************************
amazon-ebs: default                    : ok=27   changed=22   unreachable=0    failed=1
amazon-ebs:
==> amazon-ebs: Pausing before ...
```

Now you debug your instance. When you're done simply "ctrl + c" and let Packer
destroy that EC2 instance and clean it all up for you.


### Errors


#### No Keys in SSH Agent

If you see this error:

```
==> amazon-ebs: Error waiting for SSH: ssh: handshake failed: ssh: unable to
authenticate, attempted methods [none publickey], no supported methods remain
```

Then you have no SSH keys registered in you SSH Agent. Simply run `ssh-add` or
`ssh-add -K` on Mac OS. Now run `aws.debug` again.
