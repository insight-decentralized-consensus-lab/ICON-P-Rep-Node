aws_region = "us-east-1"
cluster_id = "icon"

region = "us-east-1"

//  Single
azs = ["us-east-1a"]
cidr = "10.10.0.0/16"
private_subnets = ["10.10.0.0/20"]
public_subnets = ["10.10.64.0/20"]  // Unused

log_bucket = ""
log_bucket_region = "us-east-1"
log_location_prefix = "logs"

icon_domain_name = "solidwallet.io"
node_subdomain = "net"
tracker_subdomain = "tracker"
root_domain_name = "solidwallet.io"
subdomain = "insight"
