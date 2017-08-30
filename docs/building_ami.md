# Building AMI

This project is all about building infrastructure components - mainly AMIs. In
order to do so, you have to make sure that your local project is setup correctly
and that you have sufficient AWS permission.




### AWS CLI

AWS CLI is installed automatically, but you still have to configure your AWS
profiles and credentials correctly.

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

## Building AMI

Building AMI is as easy as running:

```
make ami ROLE=base_image
```
