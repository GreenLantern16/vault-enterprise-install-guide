# Vault Enterprise Install Guide for AWS
This repo contains instructions and Terraform code for standing up HashiCorp Vault Enterprise in a reference architecture compliant configuration using the [Vault Enterprise Starter Module](https://registry.terraform.io/modules/hashicorp/vault-ent-starter/aws/latest) for AWS. It is designed to be as simple as possible to use and only requires you to adjust five variables.

## How Does It Work?
The code you'll find in this repo is broken into two parts, namely the VPC and the Vault cluster. The VPC code will stand up a basic network with the correct settings for a reference architecture Vault cluster in HA configuration. The terraform in the vault subdirectory uses the official Vault Enterprise Starter Module for AWS which takes care of the following automatically:

* Storage of TLS certificates in AWS Secrets Manager
* Storage of Vault unseal keys in AWS KMS
* Storage of your Vault license in a private S3 bucket
* A five node, HA enabled Vault cluster spread across three availability zones using Raft storage
* An AWS internal load balancer that uses a TLS cert with your own domain name
* Copies of the TLS certificate are also placed onto each Vault node for internal communication

## Installation Guide
Follow the steps below to create a production grade Vault Enterprise cluster on AWS.

### Prerequisites
* An AWS Account where you have admin rights.
* A VPC where you can deploy your Vault nodes. You can use the terraform in the included VPC subdirectory to create a suitable VPC with the correct tags and settings. See [VPC Setup](#vpc-setup) below for the correct settings.
* A domain name where you can add DNS records and to use for TLS certificates. Some basic understanding of TLS is helpful for this part.
* A copy of this repository which utilizes the most excellent [Terraform AWS Vault Enterprise Starter](https://github.com/hashicorp/terraform-aws-vault-ent-starter) module.
* Your Vault Enterprise `*.hclic` file. Ask your account representative or solutions engineer if you need a new license.

### Get the Code
Clone this Vault Enterprise Install Guide repo.

```
git clone https://github.com/scarolan/vault-enterprise-install-guide
cd vault-enterprise-install-guide
```

### AWS Account and Credentials Setup
Use the following commands to set up your AWS credentials. If you already have your credentials configured via the `aws configure` command that's fine too. **Don't ever put AWS credentials into your Terraform code.**

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

If you already have a VPC that meets these requirements you may move on to the next step. Otherwise use the terraform code in the VPC folder to build a new VPC. Only a single variable is required: `resource_name_prefix`.

The tags for your Vault nodes can be changed by adjusting the `private_subnet_tags` variable. The default settings should be fine for dev and test environments.

Run the terraform code inside of the vpc directory to build out the VPC.

Note: You can change the `region` and `azs` variables if you'd like to build your VPC in another region than the default of us-east-1.

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
NOTE: If you want to use pre-existing certificates just make sure the names of the files match the configuration in `tls.tf`.

For this step you'll need a domain name that you can add records to. For the purposes of this tutorial we'll use **vaultdemo.net** as an example. You must be either a domain administrator and able to receive admin emails about the domain or able to add records to the DNS files. This is what allows LetsEncrypt to validate your domain ownership.

If you don't have it yet install the [certbot command line tool](https://certbot.eff.org/). MacOS users can use the `brew` command to install. Linux or WSL users may install certbot using `apt` or the snap store.

```bash
brew install certbot
```

Next run the command to generate a new TLS cert:

```bash
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

Five variables are required; configure your terraform.tfvars file, replacing the variables with your own settings. Make sure the `license_filepath` setting points at your local Vault license file. In this example we're storing it on the desktop:

```
resource_name_prefix = "demo"
shared_san = "vault.vaultdemo.net"
vpc_id = "vpc-0cf321d42c7f72e13"
license_filepath = "~/Desktop/vault.hclic"
region = "us-east-1"
```

That's it! You only need to configure these five variables to run the code in this repo.

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
For this step you can use the AWS console and manually add the networks or security groups that should be allowed to talk to Vault. Go into EC2 > Security Groups > demo-vault-lb-sg and add a Custom TCP rule allowing access to port 8200 from any of the entities that require access. For demo or development purposes you may set this to `0.0.0.0/0` to keep things simple. **Don't do this in production.**

### Test Your Work
If you don't have an application or bastion host stood up yet you can use one of the Vault nodes to check the API.

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
You may now initialize your Vault cluster and begin using it. Be sure to save a copy of the unseal key and root token somewhere save!


### TLS Certificate Renewal

When it comes time to renew your TLS certificates, simply replace the old ones and re-run a `terraform apply`. Terraform will upload your new certificates into AWS secrets manager and reconfigure your ACM certificate for the load balancer. Then you can do a rolling upgrade by destroying one node at a time and allowing the auto-scaling group to re-deploy them with the new certs.
