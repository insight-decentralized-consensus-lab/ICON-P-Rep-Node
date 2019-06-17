
# ICON Public Representative Node Planning 

## Infrastructure 

### General Stages 

Plan 1:

- Stage 1 - Single Node 
- Stage 2 - Autoscaling-group 

Plan 2:

- Stage 1 - Static IPs 
- Stage 2 - Service Discovery 

If IPs are to remain static, then the stages are just plan 1. 
If automated service discovery is to be selected, then priority needs to be on how to validate 
the nodes to give access to the service discovery API. 

### Service Discovery

This is just my (Rob) uninformed opinion based on a little brainstorming after digesting the docs 

Please take these bullets with a grain of salt as I haven't talked to the devs yet. 

- Exposing a list of IPs to the world seems like a scary thing to do
- If IPs were configured dynamically through a secure service discovery mechanism, 
denial of service attacks would be harder
- To protect the list of public representative nodes, perhaps only serve traffic to 
hosts joined to a valid whitelisted domain. 
    - Domains must have valid cert to prove hosts are reps 
    - Otherwise nodes become easy attack vectors 
- As long as no p-rep knows about the full IP list, it can be decentralized among 
members and built into a mesh coordinated via gossip

#### IP Whitelisting Lambda 

While dynamic service discovery isn't in deployment, p-rep nodes can be further 
protected via a lambda function that will automatically change security group rules 
based on a heart beat parsing the IP whitelist json or triggered via some endpoint 
that will trigger a lambda with a role to update the security group.  

### SSL Certs 

To get certs for AWS, ACM easily handles this for load balancers. 
If the p-rep org decide on single node, then LetsEncrypt can be used 
in `user-data` to validate domain joining. 


## Security Governance 

TODO: Layout least privileges in IAM 
- Needs to have minimal read / write / destroy roles laid out 
TODO: Build guidance around assuming roles / passwords + what not... 
- Since infra is open source, would be good to explicitly say what not to do...

## Ops 

### CI 

- Building CI in circleci 
- Will commit keys to build pipeline and configure MFA on repo 
    - TODO: Validate ^^ with ICON 
