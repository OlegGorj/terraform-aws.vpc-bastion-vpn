[![Build Status](https://travis-ci.org/oleggorj/vpcs-with-bastionbox.terraform.svg?branch=master)](https://travis-ci.org/oleggorj/vpcs-with-bastionbox.terraform)


# vpcs-with-bastionbox.terraform

*note*: this repo is wip


1.  Go into 'dev' folder.

```
cd ~/dev
```

2.  create the public key for the dev servers

```
ssh-keygen -t rsa -C "dev_key" -f ./dev_key

```

3.  specify things like Access and secret key in some ways:

option 1 - Specify it directly in the provider (not recommended)

```
provider "aws" {
  region     = "us-west-1"
  access_key = "myaccesskey"
  secret_key = "mysecretkey"
}
```

option 2 - Using the AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables

```
$ export AWS_ACCESS_KEY_ID="myaccesskey"
$ export AWS_SECRET_ACCESS_KEY="mysecretkey"

$ terraform plan

```

Of course, there are bunch of other options to manage secrets and keys, but this is not the objective of this repo (although, it's on TODO list).

The second option is recommended because you don’t need to expose your secrets on the file.

Hence, `_main.tf` would look like:

```
provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("staging_key.pub")}"
}

```

4. Run this command on dev folder: (Terraform’s commands should be run on the environments folder).

```
cd ~/dev
terraform get
terraform plan

```

5.  and, finally, apply the changes

```
terraform apply

```

6. testing step (wip)


---
