aws_region = "us-east-1"
region = "us-east-1"

cluster_id = "icon"

////  Single
//azs = ["us-east-1a"]
//cidr = "10.10.0.0/16"
//private_subnets = ["10.10.0.0/20"]
//public_subnets = ["10.10.64.0/20"]  // Unused

//  HA
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
cidr = "10.10.0.0/16"
private_subnets = ["10.10.0.0/20", "10.10.16.0/20", "10.10.32.0/20"]
public_subnets = ["10.10.64.0/20", "10.10.80.0/20", "10.10.96.0/20"]

log_bucket = ""
log_bucket_region = "us-east-1"
log_location_prefix = "logs"


icon_domain_name = "solidwallet.io"
node_subdomain = "net"
tracker_subdomain = "tracker"
root_domain_name = "solidwallet.io"
org_subdomain = "insight"
