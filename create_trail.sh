#! /usr/bin/env bash

TRUSTDOME_TRAIL_NAME="trustdome-trail"
TRUSTDOME_TRAIL_BUCKET_NAME="trustdome-customer-trails-bucket"

aws --version >/dev/null || { echo "AWS CLI doesn't exist on this machine. Please install it and try again." && exit 1; }

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

printf "%s\n" "Creating a trail to Trustdome's bucket [$TRUSTDOME_TRAIL_BUCKET_NAME]"
aws cloudtrail create-trail --name "$TRUSTDOME_TRAIL_NAME" --s3-bucket-name "$TRUSTDOME_TRAIL_BUCKET_NAME" --is-multi-region-trail \
  && printf "%s\n" "Trail $TRUSTDOME_TRAIL_NAME created!" \
  || gracefulExit "Failed to create trail $TRUSTDOME_TRAIL_NAME"
