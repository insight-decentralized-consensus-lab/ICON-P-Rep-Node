# ICON P-Rep Node 

## Pre-Deployment Check List 

- Initialize account
- Setup local environment 
- Deploy infrastructure 


### Initialize account

- Basically follow [this guide.](https://docs.cloudposse.com/reference-architectures/cold-start/)
    - You only need to have admin privileges once as we initialize the account.  
    - Afterwards we revoke the role used to deploy all the resources and setup roles that we will use later to update 
    the resources.

### Setup local environment 

- Install terraform version 0.11.14 (version needs to exceed the one used to create state) and put in path 
    - Can be done through brew or from GH releases 
    - This is only because terragrunt currently does not support 0.12.x

```bash
wget https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
unzip terraform_0.11.14_linux_amd64.zip
sudo chmod +x terraform 
sudo mv terraform /usr/local/bin/terraform11
sudo ln -s /usr/local/bin/terraform11 /usr/local/bin/terraform
terraform --version 
```
    
- Install terragrunt 
    - Same as above but use latest version 
- Get AWS Credentials 
    - export the appropriate AWS_SECRET_ACCESS_KEY environment variables for the account you are trying to deploy to
    - aws-vault is a nice tool to have here as demonstrated in manual deployment options 

## Deploy infrastructure 

### Initialize 

**Before deploying any infrastructure, you need to initialize a config file that will hold your account name. **

Run `init.sh` with your account id and select a region to put your terraform remote state files. 

```bash
./init.sh <aws account id> <region where to put remote state> 
```

The bucket and a dynamo-db lock table will be created automatically from here on out and you should not have to 
reference the variables again.  When you move to a production environment, the icon-dev folder will be copy and 
pasted as icon-prod and the account id will be changed to point to new account. 

### Deploy all the infrastructure 

When in development, it is best practive to clean the cache between runs. 
```bash
./clean-cache.sh
```

Plan - Make sure it works. Will throw an error in some remote state references. Ignore these errors. 
```bash
cd icon-dev/us-east-1
terragrunt plan-all --terragrunt-source-update
```
**If you get an error like, traversed to root, make sure your account.tfvars is present.**


Apply - Download all the modules / providers 
```bash
cd icon-dev/us-east-1
terragrunt apply-all --terragrunt-source-update
```

Destroy - This is real and can't be undone 
```bash
cd icon-dev/us-east-1
terragrunt destroy-all --terragrunt-source-update
```

If you run into locking issues. 
```bash
terragrunt force-unlock -force <lock number>
```

## Infrastructure 

### VPC 

- One vpc per region with class B network (16 bit mask)
- Specify number of availability zones and private and public subnets deployed in each AZ
- Specify the CIDR blocks to be used.  Needs to correspond to each AZ
    - TODO: Make CIDR block calculations dynamic through CIDR calculator and discuss with ICON about standard route tables 
    
**Example CIDR Blocks: -> these will change**

| Subnet          | CIDR        |
|-----------------|-------------|
| public subnet 1 | 10.1.1.0/24 |
| public subnet 2 | 10.1.2.0/24 |
| public subnet 3 | 10.1.3.0/24 |
| private subnet 1 | 10.1.101.0/24 |
| private subnet 2 | 10.1.102.0/24 |
| private subnet 3 | 10.1.103.0/24 |


### Security Groups 

- Each service has it's own security group and associated policies to support communications over the ports 

TODO: Finalize SGs and rules 

### IAM Roles 

Several roles that can be assumed or given to users or groups within and across accounts. 

- read
- write 
- destroy 
- audit - TODO

### Keys 

TODO: Update docs to reflect dynamic key importing and options 

### Logs 

TODO: WIP

S3 buckets are created with appropriate bucket policies to allow the IAM 

### Auto Scaling Groups 

Lots of ways to run application. To understand more about the different options and the thought process behind choices, please review [these docs](docs/icon-planning.md).  Currently this architecture is focussed on an MVP which will leverage a user-data script to bootstrap the p-rep node on startup.  Over time, a move towards running on ECS could be considered.  For now, the advantages of using kubernetes have been loosely ruled out though that might change. 


## Gotchas

### Changing folder names

The names of the folders within the configuration directory (icon-dev) can't be changed when the module has been 
deployed as the name of the folder is repeated in the keys in s3 to the state file.  Make sure to migrate the state 
if you have a live deployment and want to change the name of any folders / move them in directory tree.

### Don't Use aws-vault with IAM Modifications 

[Source](https://github.com/99designs/aws-vault/issues/266#issuecomment-404738205) - AWS does not allow IAM operations with an assumed role unless it's authenticated with an MFA

### When using AWS named profiles, set proper env vars 

Normally you only need to set `AWS_DEFAULT_PROFILE=xxx` to get into credentials but in terragrunt you also need to set `AWS_PROFILE=xxx` to get it to recogize the profile in `~/.aws/credentials`.

