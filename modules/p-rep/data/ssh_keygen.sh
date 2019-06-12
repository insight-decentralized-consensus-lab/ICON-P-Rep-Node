#!/bin/bash
# ssh_key_generator - designed to work with the Terraform External Data Source provider
#   https://www.terraform.io/docs/providers/external/data_source.html
#  by Irving Popovetsky <irving@popovetsky.com>
#
#  this script takes the 3 customer_* arguments as JSON formatted stdin
#  produces public_key & private_key (contents) and the private_key_file (path) as JSON formatted stdout
#  DEBUG statements may be safely uncommented as they output to stderr

function error_exit() {
  echo "$1" 1>&2
  exit 1
}

function check_deps() {
  test -f $(which ssh-keygen) || error_exit "ssh-keygen command not detected in path, please install it"
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

function create_ssh_key() {
  script_dir=$(dirname $0)
  export ssh_key_file="${cwd}/ssh_keys/icon-${environment}-${account_id}"
   echo "DEBUG: ssh_key_file = ${ssh_key_file}" 1>&2
  if [[ ! -f "${ssh_key_file}" ]]; then
    ssh-keygen -q -t rsa -N '' -f $ssh_key_file
  fi
}

function produce_output() {
  public_key_contents=$(cat ${ssh_key_file}.pub)
   echo "DEBUG: public_key_contents ${public_key_contents}" 1>&2
  private_key_contents=$(cat ${ssh_key_file} | awk '$1=$1' ORS='  \n')
   echo "DEBUG: private_key_contents ${private_key_contents}" 1>&2
   echo "DEBUG: private_key_file ${ssh_key_file}" 1>&2
  jq -n \
    --arg public_key "$public_key_contents" \
    --arg private_key "$private_key_contents" \
    --arg private_key_file "$ssh_key_file" \
    '{"public_key":$public_key,"private_key":$private_key,"private_key_file":$private_key_file}'
}

check_deps
create_ssh_key
produce_output