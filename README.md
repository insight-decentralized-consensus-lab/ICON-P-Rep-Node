
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

- Install terraform version 0.11.x (14 at the time of writing) and put in path 
    - Can be done through brew or from GH releases 
    - This is only because terragrunt currently does not support 0.12.x
- Install terragrunt 
    - Same as above but use latest version 
- Get AWS Credentials 
    - export the appropriate AWS_SECRET_ACCESS_KEY environment variables for the account you are trying to deploy to. 

### Deploy infrastructure 

```bash
./deploy.sh 
```

```bash
aws-vault exec hc-root-admin -- terragrunt force-unlock -force <lock number>
aws-vault exec hc-root-admin -- terragrunt destroy --terragrunt-source-update
```
## Infrastructure 
    
### VPC 

Two 

### Security Groups 


### P-Rep Autoscaling Groups 


### IAM Roles 

Several roles that can be assumed or given to users or groups within and across accounts. 

- read
- write 
- destroy 
- audit - TODO

