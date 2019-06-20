resource "aws_iam_policy" "terraform_update_policy" {
    name = "terraform_update_policy"
    path = "/"
    policy = "${data.aws_iam_policy_document.terraform_update_policy.json}"
}

data "aws_iam_policy_document" "terraform_update_policy" {
    statement {
        sid = "1"
        actions = [
			"ec2:ReplaceNetworkAclAssociation",
			"ec2:ModifyNetworkInterfaceAttribute",
			"autoscaling:UpdateAutoScalingGroup",
			"ec2:ModifyVpcAttribute",
			"ec2:ModifyVpcEndpoint",
			"ec2:ModifySubnetAttributes",
			"ec2:ModifyInstanceAttribute",
			"ec2:ReplaceRouteTableAssociation",
			"ec2:ReplaceRouteTableAssociation",
			"route53:ChangeResourceRecordSets",
			"route53:ChangeTagsForResource",
			"route53:UpdateHealthCheck",
			"elasticloadbalancing:ModifyLoadBalancerAttributes",
			"rds:AddTagsToResource"
        ]
        resources = [
            "*",
        ]
    }
}