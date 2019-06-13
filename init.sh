#!/usr/bin/env bash

ACCOUNT_ID=$1

if [[ $# != 1 ]]   # checks that number of inputs is exactly one
 then
  echo "Too many inputs."
  exit 2
#  [[ $ACCOUNT_ID =~ ^[0-9]{,12}$ ]] && ((number=100000000000#$number))
elif [[ $ACCOUNT_ID -lt 0 || $ACCOUNT_ID -gt 999999999999 ]]   # checks that the input is within the desired range
 then
  echo "Input outside acceptable range."
  exit 3
fi

output=`d "$ACCOUNT_ID"`


#find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;


read -n1 -p "What is your account id]" account_id
ACCOUNT_ID = account_id

echo $ACCOUNT_ID

#read -n1 -p "What do you want to do [plan(p), apply(a), destroy]" doit
#case $doit in
#  plan|p) terragrunt plan --terragrunt-source-update -- ;;
#  apply|a) echo no ;;
#  destroy) echo no ;;
#  *) echo dont know ;;
#esac
#
#find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
#
#
#cat<<EOF >> ./account.tfvars
#account_id = "$ACCOUNT_ID"
#aws_allowed_account_ids = ["$ACCOUNT_ID"]
#terraform_state_region = "$REMOTE_STATE_REGION"
#terraform_state_bucket = "terraform-states-$ACCOUNT_ID"
#EOF

