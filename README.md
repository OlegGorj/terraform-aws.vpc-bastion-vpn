[![Build Status](https://travis-ci.org/OlegGorj/vpc-with-bastionbox.terraform.svg?branch=master)](https://travis-ci.org/OlegGorj/vpc-with-bastionbox.terraform)


# vpcs-with-bastionbox.terraform


### Deployment:

![](deployment.jpg)

### Prerequisites

First things first - how to install Terraform on you Mac or Win, follow this [link](https://www.terraform.io/intro/getting-started/install.html)

### Step-by-step instructions:

#### 1.  Go into 'terraform' folder.

```
cd ~/terraform
```

#### 2.  Create the keys pair for the dev servers (at this point, assume DEV environment setup)

```
ssh-keygen -t rsa -C "dev_key" -f ~/.ssh/dev_key

```

#### 3.  Specify things like Access and secret key in some ways:

*Option 1* - Specify it directly in the provider (not recommended)

```
provider "aws" {
  region     = "us-west-1"
  access_key = "myaccesskey"
  secret_key = "mysecretkey"
}
```
Obviously, it has some downsides, like, you would need to put your credentials into TF script, which is very bad idea, hence it's highly NOT recommended.


*Option 2* - Using the shared_credentials_file to pass environment credentials

```
provider "aws" {
  region = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
}

```

where variable `${var.cred-file}` looks like:

```
variable "cred-file" {
  default = "~/.aws/credentials"
}

```

Node: `~/.aws/credentials` points to credentials file located in your home directory. For development purposes, this might be fine, but for PROD deployment, this will needs to be replaced with call to Vault.

File `~/.aws/credentials` has following format:

```
[default]
aws_access_key_id = <your access key>
aws_secret_access_key = <your secret key>
```

Of course, there are bunch of other options to manage secrets and keys, but this is not the objective of this repo (although, it's on TODO list).

The second option is *recommended* because you don’t need to expose your secrets on TF script. And, again, proper integration with the vault and KMS is on my TODO.

Hence, `_main.tf` would look like:

```
provider "aws" {
  region = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("dev_key.pub")}"
}

```
#### 4. Directory structure would look like this:

```
| => tree
.
├── Makefile
├── README.md
├── deploy.sh
├── deployment.jpg
├── deployment.xml
├── set-hostname.tf
├── terraform
│   ├── _main.tf
│   ├── modules
│   │   ├── bastion
│   │   │   └── main.tf
│   │   ├── networking
│   │   │   └── main.tf
│   │   ├── openvpn
│   │   │   └── main.tf
│   │   └── web
│   │       ├── files
│   │       │   └── user_data.sh
│   │       ├── main.tf
│   │       └── variables.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   ├── terraform.tfvars
│   └── variables.tf
└── terraform.tfstate

```

#### 5. Run this command on terraform folder: (Terraform’s commands should be run on the environments folder).

```
=> cd ~/terraform
=> terraform init
=> terraform get
=> terraform plan

```

You should see a lot of output ending with this

```
Plan: 21 to add, 0 to change, 0 to destroy.

```

#### 6.  and, finally, apply the changes

```
=> terraform apply

```

After a while you should see this...

```

Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

Outputs:

elb_hostname = dev-web-lb-702130120.us-west-1.elb.amazonaws.com


```

#### 7.  Access Web server via LB

If you run command `terraform output elb_hostname`, you should get public DNS address of LB

```
dev-web-lb-702130120.us-west-1.elb.amazonaws.com
```

Copy and paste it into the browser window, specify port 80

```
dev-web-lb-702130120.us-west-1.elb.amazonaws.com:80
```

You should see Nginx welcome screen.
If you'd like to play around with Nginx home page, make changes to shell script `terraform/modules/web/files/user_data.sh`



#### 8. SSH to Web nodes

Your web nodes don't have public IPs, hence in order to SSH them, you need to use bastion node.
Get the bastion node public IP (in my case it was ec2-18-144-46-178.us-west-1.compute.amazonaws.com) and SSH to it with the flag `-A` to enable agent forwarding, as such:

```
chmod 400 ~/.ssh/dev_key.pub

ssh-add -K ~/.ssh/dev_key

ssh -A ubuntu@ec2-18-144-46-178.us-west-1.compute.amazonaws.com

```

*note:  It is not a good idea to use "SSH-agent forwarding," because this can pose a security risk. Instead you should invoke ssh with "-W" to forward stdin/stdout to your internal destination host.*


At this point, you should see prompt of Bastion host:
```
ubuntu@ip-10-0-1-71:
```

Now, inside Bastion host, you can connect to Web servers (you can find Web private IPs using Console).

Web node 1:
```
ssh ubuntu@10.0.2.182

```

Web node 2:
```
ssh ubuntu@10.0.2.33

```

#### 9. OpenVPN

At the end of execution of `terraform apply`, you should see the following lines, the result of execution of openvpn module

```
aws_vpn_instance_public_dns = ec2-13-56-228-90.us-west-1.compute.amazonaws.com
aws_vpn_instance_public_ip = 13.56.228.90
client_configuration_file = docker.ovpn
closing_message = Your VPN is ready! Check out client configuration file to configure your client! Have fun!'
elb_hostname = dev-web-lb-163033253.us-west-1.elb.amazonaws.com

```

VPN client config `docker.ovpn` file will be copied to your home directory.

Publich DNS name of VPN is indicated by variable `aws_vpn_instance_public_dns`


#### 10. VPN client

Use generated file `docker.ovpn` with an OpenVPN client. In OS X, you can install openvpn using command `brew install openvpn`.

Then, once that is done,

```
$ sudo openvpn --config awesome-personal-vpn.ovpn

```

Alternatively, use GUI client Tunnelblick at [this link](https://openvpn.net/index.php/access-server/docs/admin-guides/183-how-to-connect-to-access-server-from-a-mac.html)

Once Tunnelblick is installed, import `docker.ovpn` file.



#### 11. Destroy everything

And the last step is to destroy all setup


```
=> terraform destroy

```

---


## TODOs

- split public subnet into 2 subnets: public and private Devops
- use docker to properly deploy Ngnix
- add Vault and KMS to manage secrets and keys



---
