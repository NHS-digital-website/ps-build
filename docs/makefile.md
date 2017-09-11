# Makefile

All you need to know about Makefile and how we use it in this project.

* First time user - `make init`
* It's broken, I got an error "..." - `make clean init`
* If in doubt - run `make help`




## Local Override

You can permanently override variables by putting it in the `.mk` file. For
instance you might want to specify `USERNAME` if you are often running `ami_debug`
command.

```
USERNAME ?= firstname.lastename
```

All variables used in Makefile are defined at the top of the file in alphabetical
order. Please keep it that way.




## AWS Credentials and CLI Access

In order to authorise your terminal/console to access AWS CLI for 60min ...

```
$(make aws-sudo PROFILE=nhsd-rps-sandbox TOKEN=100200)
```

where `PROFILE` is your AWS CLI profile name and `TOKEN` is your MFA token.
