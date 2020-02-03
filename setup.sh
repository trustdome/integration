#! /usr/bin/env bash

TRUSTDOME_ROLE_NAME="TrustdomeRole"
TRUSTDOME_READ_POLICY_NAME="TrustdomeReadPolicy"
TRUSTDOME_READ_POLICY='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["iam:GenerateServiceLastAccessedDetails","iam:Get*","iam:List*","iam:SimulateCustomPolicy","iam:SimulatePrincipalPolicy"],"Resource":"*"},{"Effect":"Allow","Action":["s3:HeadBucket","s3:GetBucketAcl","s3:GetBucketLocation","s3:GetBucketPolicy","s3:GetBucketPolicyStatus","s3:List*"],"Resource":"*"},{"Effect":"Allow","Action":"ec2:Describe*","Resource":"*"},{"Effect":"Allow","Action":"elasticloadbalancing:Describe*","Resource":"*"},{"Effect":"Allow","Action":["cloudwatch:Describe*"],"Resource":"*"},{"Effect":"Allow","Action":"autoscaling:Describe*","Resource":"*"}]}'
ASSUME_ROLE_POLICY_JSON='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::365477817725:root"},"Action":"sts:AssumeRole","Condition":{}}]}'

if [[ -z "$1" ]]; then
  echo "Usage: $0 <AWS account ID> [aws-policy-file.json]"
  exit 1
fi

aws --version >/dev/null || { echo "AWS CLI doesn't exist on this machine. Please install it and try again." && exit 1; }

if [[ -n "$2" ]]; then
  TRUSTDOME_READ_POLICY="file://$2"
fi

COMMAND_CREATE_POLICY=(aws iam create-policy --policy-name "$TRUSTDOME_READ_POLICY_NAME" --policy-document "$TRUSTDOME_READ_POLICY")
COMMAND_CREATE_ROLE=(aws iam create-role --role-name "$TRUSTDOME_ROLE_NAME" --assume-role-policy-document "$ASSUME_ROLE_POLICY_JSON")
COMMAND_ATTACH_POLICY_TO_ROLE=(aws iam attach-role-policy --role-name "$TRUSTDOME_ROLE_NAME" --policy-arn "arn:aws:iam::$1:policy/$TRUSTDOME_READ_POLICY_NAME")

function onExit() {
  if [[ -z "$MESSAGE" ]]; then
    printf "\n%s\n" "Finished successfully."
  else
    printf "\n%s\n" "Finished with an error: [$MESSAGE]"
  fi
}

trap onExit EXIT

function gracefulExit() {
  MESSAGE="$1"
  exit 1
}

function handleRoleCreated() {
  printf "%s\n" "Role $TRUSTDOME_ROLE_NAME created!"
  local RED=$(tput setaf 1)
  local BOLD=$(tput bold)
  local NORMAL=$(tput sgr0)
  while read -r line
  do
    ROLE_ARN=$(echo "$line" | cut -d'"' -f4)
    echo "$line" | grep "Arn" > /dev/null && printf "%s\n" "${RED}Please send the role ARN to Trustdome! Here it is: ${BOLD}$ROLE_ARN${NORMAL}" && break
  done
}

printf "%s\n" "Creating policy..."
"${COMMAND_CREATE_POLICY[@]}" && printf "%s\n" "Policy $TRUSTDOME_READ_POLICY_NAME created!" || gracefulExit "Failed to create policy"
sleep 2
printf "%s\n" "Creating role..."
"${COMMAND_CREATE_ROLE[@]}" | handleRoleCreated || gracefulExit "Failed to create role"
sleep 2
printf "%s\n" "Attaching policy to role..."
"${COMMAND_ATTACH_POLICY_TO_ROLE[@]}" && printf "%s\n" "Policy attached to role!" || gracefulExit "Failed to attach policy to role"
