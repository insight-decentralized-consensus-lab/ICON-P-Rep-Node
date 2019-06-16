#!/usr/bin/env bash
if [[ $# >= 2 ]]   # checks that number of inputs is exactly one
 then
  echo "Enter the account id and remote state region \n ie: ./init.sh 123456789012 us-east-1"
  exit 2
fi
ACCOUNT_ID=$1
REMOTE_STATE_REGION=$2
LOCAL_KEY_FILE=$3

cat<<EOF > ./icon-dev/account.tfvars
account_id = "$ACCOUNT_ID"
aws_allowed_account_ids = ["$ACCOUNT_ID"]
terraform_state_region = "$REMOTE_STATE_REGION"
terraform_state_bucket = "terraform-states-$ACCOUNT_ID"
local_key_file = "$LOCAL_KEY_FILE"
EOF
