# What if I want to rebuild codebuild hippo Image

To build and push new codebuild docekr image follow these steps:

```
cd docker/codebuild/hippo
docker build . --tag 186991146235.dkr.ecr.eu-west-1.amazonaws.com/codebuild/hippo:latest

# login to AWS ECR and push latest image
cd ../../..
$(make aws-sudo PROFILE=... TOKEN=...)
$(.venv/bin/aws ecr get-login --no-include-email)
docker push 186991146235.dkr.ecr.eu-west-1.amazonaws.com/codebuild/hippo
```

Where:

* `PROFILE` is you AWS configuration profile for accessing NHSD account
* `TOKEN` is your MFA token
