resource "aws_iam_policy" "terraform_delete_policy" {
    name = "terraform_delete_policy"
    path = "/"
    policy = "${data.aws_iam_policy_document.terraform_delete_policy.json}"
}


data "aws_iam_policy_document" "terraform_delete_policy" {
    statement {
        sid = "1"
        actions = [
			"ec2:DeleteNetworkAcl",
			"ec2:DeleteNetworkAclEntry",
			"ec2:DetachNetworkInterface",
			"ec2:DeleteNetworkInterface",
			"autoscaling:DetachLoadbalancers",
			"autoscaling:DeleteAutoScalingGroup",
			"autoscaling:DeleteLaunchConfiguration",
			"ec2:DeleteVpc",
			"ec2:DeleteVpcEndpoints",
			"ec2:DeleteVpc",
			"ec2:DeleteVpc",
			"ec2:DeleteVpcPeeringConnection",
			"ec2:DeleteSubnet",
			"ec2:DeleteTags",
			"ec2:TerminateInstances",
			"ec2:UnmonitorInstances",
			"ec2:RevokeSecurityGroupIngress",
			"ec2:RevokeSecurityGroupEgress",
			"ec2:DeleteSecurityGroup",
			"ec2:RevokeSecurityGroupEgress",
			"ec2:RevokeSecurityGroupIngress",
			"ec2:DetachInternetGateway",
			"ec2:DeleteInternetGateway",
			"ec2:DeleteRoute",
			"ec2:DisableVGWRoutePropagation",
			"ec2:DisassociateRouteTable",
			"ec2:DeleteRouteTable",
			"ec2:ReleaseAddress",
			"ec2:DisassociateAddress",
			"ec2:DisassociateRouteTable",
			"route53:DeleteHealthCheck",
			"ec2:DeleteVolume",
			"ec2:DetachVolume",
			"elasticloadbalancing:DeleteLoadBalancer",
			"elasticloadbalancing:DeleteLoadBalancerListeners",
			"elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
			"elasticloadbalancing:RemoveTags",
			"iam:DeleteInstanceProfile",
			"iam:RemoveRoleFromInstanceProfile"
        ]
        resources = [
            "*",
        ]
    }
}