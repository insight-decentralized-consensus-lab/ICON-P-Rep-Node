resource "aws_iam_policy" "terraform_read_policy" {
    name = "terraform_read_policy"
    path = "/"
    policy = "${data.aws_iam_policy_document.terraform_read_policy.json}"
}

data "aws_iam_policy_document" "terraform_read_policy" {
    statement {
        sid = "1"
        actions = [
			"ec2:DescribeNetworkAcls",
			"ec2:DescribeNetworkInterfaceAttributes",
			"ec2:DescribeNetworkInterfaces",
			"autoscaling:DescribeAutoScalingGroups",
			"elasticloadbalancing:DescribeInstanceHealth",
			"autoscaling:DescribeLaunchConfiguration",
			"ec2:DescribeSecurityGroups",
			"ec2:DescribeVpcAttribute",
			"ec2:DescribeVpc",
			"ec2:DescribeVpcEndpoints",
			"ec2:DescribeVpcPeeringConnections",
			"ec2:DescribeSubnets",
			"ec2:DescribeImages",
			"ec2:DescribeVolumes",
			"ec2:DescribeInstances",
			"ec2:DescribeSecurityGroups",
			"ec2:DescribeSecurityGroups",
			"ec2:DescribeSecurityGroups",
			"ec2:DescribeInternetGateways",
			"ec2:DescribeRouteTable",
			"ec2:DescribeAddresses",
			"ec2:DescribeRouteTable",
			"route53:GetHostedZone",
			"route53:ListResourceRecordSets",
			"route53:GetHealthCheck",
			"route53:ListTagsForResource",
			"ec2:DescribeVolumes",
			"ec2:DescribeVolumes",
			"elasticloadbalancing:DescribeLoadBalancerAttributes",
			"elasticloadbalancing:DescribeLoadBalancers",
			"elasticloadbalancing:DescribeTags",
			"iam:GetInstanceProfile",
			"iam:GetPolicy",
			"iam:GetRole",
			"rds:DescribeDBSubnetGroups",
			"elasticloadbalancing:DescribeTargetGroups",
			"iam:GetPolicyVersion",
			"elasticloadbalancing:DescribeTargetGroupAttributes",
			"rds:DescribeDBInstances",
			"elasticloadbalancing:DescribeListeners",
			"iam:ListEntitiesForPolicy",
			"elasticloadbalancing:DescribeRules",
			"iam:ListPolicyVersions"
        ]
        resources = [
            "*",
        ]
    }
}