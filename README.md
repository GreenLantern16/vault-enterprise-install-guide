# Vault Enterprise Install Guide
This repo contains instructions and Terraform code for standing up HashiCorp Vault Enterprise in a reference architecture compliant configuration using the [Vault Enterprise Starter Module](https://github.com/hashicorp/terraform-aws-vault-ent-starter). It is designed to be as simple as possible to use and only requires you to adjust three variables.

## How Does It Work?
The code you'll find in this repo is broken into two parts, namely the VPC and the Vault cluster. The VPC code will stand up a basic network with the correct settings for a reference architecture Vault cluster in HA configuration. The terraform in the vault subdirectory uses the official Vault Enterprise Starter Module which takes care of the following automatically:

* Storage of TLS certificates in AWS Secrets Manager
* Storage of Vault unseal keys in AWS KMS
* A five node, HA enabled Vault cluster spread across three availability zones using Raft storage
* An AWS internal load balancer that uses the TLS cert
* Copies of the TLS certificate are also placed onto each Vault node for internal communication

## Installation Guide
Follow the steps below to create a production grade Vault Enterprise cluster on AWS.

### Prerequisites
* An AWS Account where you have admin rights. This guide assumes you are beginning with a fresh, empty AWS account. You can get an AWS lab account for eight hours using the [AWS Open Lab Instruqt](https://play.instruqt.com/hashicorp/tracks/aws-open-lab) track.
* A VPC where you can deploy your Vault nodes. You can use the terraform in the included VPC subdirectory to create a suitable VPC with the correct tags and settings. See #vpc-setup below for the correct settings.
* A domain name where you can add DNS records and to use for TLS certificates. HashiCorp SEs may use a subdomain of the hashidemos.com zone in the shared SE AWS account, [as documented in Confluence](https://hashicorp.atlassian.net/wiki/spaces/~844747070/pages/1018757599/Using+new+hashidemos.io+DNS+Zone). Some basic understanding of TLS is helpful for this part.
* A local copy of both this repository and the [Terraform AWS Vault Enterprise Starter](https://github.com/hashicorp/terraform-aws-vault-ent-starter) module.

### Get the Code
Clone the Vault Enterprise Starter repo and this Install Guide repo. You'll be doing all your work inside the vault-enterprise-install-guide repo, so you may wish to open that directory in your favorite text editor. No changes are required to the starter module, but you'll need a local copy because it's not in the public registry yet.

```
git clone https://github.com/scarolan/vault-enterprise-install-guide
git clone https://github.com/hashicorp/terraform-aws-vault-ent-starter
```

### AWS Account and Credentials Setup
Use the following commands to set up your AWS credentials. If you need an AWS account to build in, the [AWS Open Lab Instruqt track](https://play.instruqt.com/hashicorp/tracks/aws-open-lab/) will give you an environment for up to 8 hours.

```
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=YOURACCESSKEY
export AWS_SECRETACCESS_KEY=YOURSECRETKEY
```

### VPC Setup
You'll need a VPC that meets the following requirements:

* Three public subnets
* Three NAT gateways, one in each public subnet
* Three private subnets. Make sure your private subnets are tagged correctly so the Vault module can find them

If you already have a VPC that meets these requirements you may move on to the next step. Otherwise use the terraform code in the VPC folder to build a new VPC. Only a single variable is required: `friendly_name_prefix`.

The tags for your Vault nodes can be changed by adjusting the `private_subnet_tags` variable. The default settings should be fine for most demos and POV trials.

Run the terraform code inside of the vpc directory to build out the VPC:
```
cd vpc
terraform init
terraform plan
terraform apply -auto-approve
```

You'll see outputs that look something like this. Make note of the VPC id for the next steps.
```
Outputs:

private_subnet_tags = tomap({
  "Vault" = "deploy"
})
vpc_id = "vpc-0cf321d42c7f72e13"
```

Once you've succesfully built a VPC (or already have one prepared) proceed to the next step.

### Generate a LetsEncrypt TLS Certificate
NOTE: If you already have your certificate, fullchain and privkey files from a previous build, you can reuse them as long as the cert has not expired. Or if a customer wants to provide their own TLS certs that's also fine, just make sure the names of the files match the configuration in `tls.tf`.

For this step you'll need a domain name that you can add records to. For the purposes of this tutorial we'll use **vaultdemo.net** as an example. You must be either a domain administrator and able to receive admin emails about the domain or able to add records to the DNS files. This is what allows LetsEncrypt to validate your domain ownership.

If you don't have it yet install the certbot command line tool:

```
brew install certbot
```

Next run the command to generate a new TLS cert:

```
sudo certbot certonly --manual --preferred-challenges dns
```

Follow the instructions to create a new `TXT` record in your DNS provider. This is basically just a way to prove that you have admin rights and are allowed to make changes for this domain. It can take a few minutes to propagate so make sure you give it some time before proceeding with the LetsEncrypt process by hitting ENTER. You can use the link the tool provides in the output to check whether the record is ready, for example:

https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.vault.vaultdemo.net

Once it's ready go ahead and finish provisioning your TLS certificate.

Your brand new TLS cert and key will be stored in the following directories:
```
Full Chain is saved at:  /etc/letsencrypt/live/vault.vaultdemo.net/fullchain.pem
Certificate is saved at: /etc/letsencrypt/live/vault.vaultdemo.net/cert.pem
Key is saved at:         /etc/letsencrypt/live/vault.vaultdemo.net/privkey.pem
```

Next, copy the three files into the vault subdirectory of this repo. Example:

```
cd vault
```

```
sudo cp /etc/letsencrypt/live/vault.vaultdemo.net/fullchain.pem .
sudo cp /etc/letsencrypt/live/vault.vaultdemo.net/cert.pem .
sudo cp /etc/letsencrypt/live/vault.vaultdemo.net/privkey.pem .
```

You'll also need to change the permissions on the privkey.pem file to be readable by Terraform:

```
chmod 644 privkey.pem
```

Terraform will use these three files to generate certificates that will be used on both the load balancer and on each Vault instance.

### Configure Your Variables and Module Path
Before you go further make sure you are in the **vault** subdirectory.

Three variables are required; configure your terraform.tfvars file, replacing the variables with your own settings:

```
friendly_name_prefix = "demo"
shared_san = "vault.vaultdemo.net"
vpc_id = "vpc-0cf321d42c7f72e13"
```

The only other edit required is on line 9 of main.tf. Update the source to the path where you cloned the Terraform Enterprise Vault Starter module.

```
  # Change this source to wherever you cloned the terraform-aws-vault-ent-starter module.
  # This module is not in the public registry yet.
  source               = "/Users/scarolan/git_repos/terraform-aws-vault-ent-starter"
```

### Build the Vault Cluster
Great, you're ready to build the cluster. Run these commands from within the **vault** subdirectory:

```
terraform init
terraform plan
terraform apply -auto-approve
```

If all goes well you should see output like the following:

```
Outputs:

leader_tls_servername = "vault.vaultdemo.net"
vault_lb_dns_name = "internal-demo-vault-lb-847388178.us-east-1.elb.amazonaws.com"
```

### Create a CNAME record for the Vault cluster
This last DNS edit will allow you to use the DNS name you chose for your Vault cluster for internal access by EC2 instances and other AWS services.  Add a CNAME record like so in your DNS provider:

```
vault.vaultdemo.net  CNAME internal-demo-vault-lb-847388178.us-east-1.elb.amazonaws.com.
```

This essentially acts as a pointer to make sure requests for `vault.vaultdemo.net` get to the right internal load balancer.

### Enable Access to Vault
For this step you can use the AWS console and manually add the networks or security groups that should be allowed to talk to Vault. Go into EC2 > Security Groups > demo-vault-lb-sg and add a Custom TCP rule allowing access to port 8200 from any of the entities that require access. For demo and POV purposes you may set this to `0.0.0.0/0` to keep things simple. **Don't do this in production.**

### Test Your Work
If you don't have an application or bastion hosts stood up yet you can use one of the Vault nodes to check the API.

Go into EC2 > Instances > Any Vault Instance > Connect to Instance.

Select "Session Manager" and you'll get a shell prompt on the Vault node.

Switch into a Bash shell:
```
/bin/bash
```

Export the VAULT_ADDR environment variable and check Vault's status:
```
export VAULT_ADDR=https://vault.vaultdemo.net:8200
vault status
```

You should see output like the following, which means your Vault cluster is up and ready for initialization:

```
Key                      Value
---                      -----
Recovery Seal Type       awskms
Initialized              false
Sealed                   true
Total Recovery Shares    0
Threshold                0
Unseal Progress          0/0
Unseal Nonce             n/a
Version                  1.7.2+ent
Storage Type             raft
HA Enabled               true
```

### Next Steps
From this point forward you can use this Vault cluster for a POV or demo. This repo can also be used inside a customer dev account for standing up a private trial or demo instance.